import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_v2ray_client/flutter_v2ray.dart';
import '../models/server_config.dart';
import '../models/subscription.dart';
import '../services/storage_service.dart';
import '../services/subscription_service.dart';
import '../widgets/server_list_item.dart';
import '../widgets/add_menu.dart';
import '../widgets/overflow_menu.dart';
import 'add_subscription_page.dart';
import '../log_viewer_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final StorageService _storageService = StorageService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  late final V2ray _v2ray;

  final ValueNotifier<V2RayStatus> _v2rayStatus = ValueNotifier<V2RayStatus>(
    V2RayStatus(),
  );

  List<ServerConfig> _allServers = [];
  List<Subscription> _subscriptions = [];
  List<String> _bypassSubnets = [];
  String? _selectedServerId;
  bool _proxyOnly = false;
  bool _isTestingDelays = false;
  final ValueNotifier<int> _testedCountNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> _totalToTestNotifier = ValueNotifier<int>(0);
  String? _coreVersion;
  bool _isLoading = true;

  final GlobalKey<AnimatedListState> _allServersListKey =
      GlobalKey<AnimatedListState>();
  final Map<String, GlobalKey<AnimatedListState>> _subListKeys = {};

  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _v2ray = V2ray(
      onStatusChanged: (status) {
        _v2rayStatus.value = status;
      },
    );
    _initV2Ray();
    _loadData();
  }

  Future<void> _initV2Ray() async {
    await _v2ray.initialize(
      notificationIconResourceType: "mipmap",
      notificationIconResourceName: "ic_launcher",
    );
    _coreVersion = await _v2ray.getCoreVersion();
    if (mounted) setState(() {});
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _storageService.init();
    _allServers = await _storageService.loadServers();
    _subscriptions = await _storageService.loadSubscriptions();
    _selectedServerId = await _storageService.loadSelectedServer();
    _bypassSubnets = await _storageService.loadBypassSubnets();
    _proxyOnly = await _storageService.loadProxyOnly();

    _updateTabController();

    setState(() => _isLoading = false);
  }

  void _updateTabController() {
    final oldIndex = _tabController?.index ?? 0;
    _tabController?.dispose();
    _tabController = TabController(
      length: _subscriptions.length + 1,
      vsync: this,
    );
    if (oldIndex < _tabController!.length) {
      _tabController!.index = oldIndex;
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _v2rayStatus.dispose();
    super.dispose();
  }

  void _connect() async {
    setState(() => _isTestingDelays = false);
    if (_selectedServerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a server first')),
      );
      return;
    }

    final server = _allServers.firstWhere((s) => s.id == _selectedServerId);

    if (await _v2ray.requestPermission()) {
      _v2ray.startV2Ray(
        remark: server.remark,
        config: server.fullConfig,
        proxyOnly: _proxyOnly,
        bypassSubnets: _bypassSubnets,
        notificationDisconnectButtonName: "DISCONNECT",
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Permission Denied')));
      }
    }
  }

  void _importFromClipboard() async {
    if (await Clipboard.hasStrings()) {
      try {
        final String link =
            (await Clipboard.getData('text/plain'))?.text?.trim() ?? '';
        final server = _subscriptionService.parseUrl(link);
        if (server != null) {
          await _storageService.addServer(server);
          await _loadData();
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Server imported')));
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  void _addSubscription() async {
    final result = await Navigator.push<Subscription>(
      context,
      MaterialPageRoute(builder: (context) => const AddSubscriptionPage()),
    );

    if (result != null) {
      await _storageService.addSubscription(result);
      _updateSubscription(result);
    }
  }

  Future<void> _updateSubscription(Subscription sub) async {
    setState(() => _isLoading = true);
    try {
      final servers = await _subscriptionService.fetchSubscription(sub);
      await _storageService.removeServersBySubscription(sub.id);
      final allServers = await _storageService.loadServers();
      allServers.addAll(servers);
      await _storageService.saveServers(allServers);

      final updatedSub = sub.copyWith(
        lastUpdated: DateTime.now(),
        serverCount: servers.length,
      );
      await _storageService.updateSubscription(updatedSub);
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update subscription: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _testDelay(ServerConfig server) async {
    if (!mounted) return;
    server.isTesting = true;
    try {
      final delay = await _v2ray.getServerDelay(
        config: server.fullConfig,
        url: 'https://www.google.com/generate_204',
      );

      server.delay = delay;
      await _storageService.updateServer(server);

      if (mounted) {
        // Immediate UI sort when a result is available
        setState(() {
          _sortServers();
        });
      }
    } on PlatformException catch (e) {
      final errorStr = (e.message ?? '').toLowerCase();
      // AGGRESSIVE PRUNING: Delete unreachable configurations immediately
      if (errorStr.contains('tls handshake timeout') ||
          errorStr.contains('io: read/write on closed pipe') ||
          errorStr.contains('eof')) {
        await _removeServerImmediately(server);
      } else {
        // Mark as timeout for other transient errors
        server.delay = 0;
        await _storageService.updateServer(server);
        if (mounted) {
          setState(() {
            _sortServers();
          });
        }
      }
    } catch (e) {
      server.delay = 0;
      if (mounted) {
        setState(() {
          _sortServers();
        });
      }
    } finally {
      server.isTesting = false;
      if (mounted) {
        _testedCountNotifier.value++;
      }
    }
  }

  Future<void> _removeServerImmediately(ServerConfig server) async {
    await _storageService.removeServer(server.id);
    if (mounted) {
      setState(() {
        _allServers.removeWhere((s) => s.id == server.id);
        if (_totalToTestNotifier.value > 0) {
          _totalToTestNotifier.value--;
        }
      });
    }
  }

  void _sortServers() {
    _allServers.sort((a, b) {
      // 1. Valid delays (> 0) come first, sorted ascending
      // 2. Untested delays (-1) come next
      // 3. Failed/Timeout (0) come last
      if (a.delay > 0 && b.delay > 0) return a.delay.compareTo(b.delay);
      if (a.delay > 0) return -1;
      if (b.delay > 0) return 1;
      if (a.delay == -1 && b.delay == 0) return -1;
      if (a.delay == 0 && b.delay == -1) return 1;
      return 0;
    });
  }

  void _editBypassSubnets() async {
    final controller = TextEditingController(text: _bypassSubnets.join('\n'));
    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Bypass Subnets'),
            content: TextField(
              controller: controller,
              maxLines: 10,
              decoration: const InputDecoration(
                hintText: 'Enter subnets (one per line)\ne.g. 192.168.1.0/24',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text('Save'),
              ),
            ],
          ),
    );

    if (result != null) {
      final subnets =
          result.trim().split('\n').where((s) => s.trim().isNotEmpty).toList();
      await _storageService.saveBypassSubnets(subnets);
      setState(() => _bypassSubnets = subnets);
    }
  }

  Future<void> _testAllDelays() async {
    if (_isTestingDelays) {
      setState(() => _isTestingDelays = false);
      return;
    }

    List<ServerConfig> serversToTest;
    final currentIndex = _tabController?.index ?? 0;

    if (currentIndex == 0) {
      // "All Servers" tab - snapshot everything
      serversToTest = List<ServerConfig>.from(_allServers);
    } else {
      // Specific subscription tab - test only servers in this group
      final subscriptionId = _subscriptions[currentIndex - 1].id;
      serversToTest =
          _allServers.where((s) => s.subscriptionId == subscriptionId).toList();
    }

    if (serversToTest.isEmpty) return;

    setState(() {
      _isTestingDelays = true;
      _testedCountNotifier.value = 0;
      _totalToTestNotifier.value = serversToTest.length;
      for (var server in serversToTest) {
        server.delay = -1;
      }
    });

    // POOL-BASED CONCURRENT PINGING (Concurrency of 10)
    final List<ServerConfig> queue = List.from(serversToTest);
    final List<Future<void>> workers = [];
    const int maxConcurrency = 10;

    for (int i = 0; i < maxConcurrency && i < serversToTest.length; i++) {
      workers.add(() async {
        while (queue.isNotEmpty && _isTestingDelays && mounted) {
          final server = queue.removeAt(0);
          await _testDelay(server);
        }
      }());
    }

    await Future.wait(workers);

    if (mounted) {
      setState(() {
        _isTestingDelays = false;
        _sortServers(); // Final sort for stability
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _allServers.isEmpty && _subscriptions.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('V2Ray Client'),
        bottom:
            _tabController != null
                ? TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: [
                    const Tab(text: 'All Servers'),
                    ..._subscriptions.map((sub) => Tab(text: sub.name)),
                  ],
                )
                : null,
        actions: [
          IconButton(
            icon: Icon(_isTestingDelays ? Icons.timer_off : Icons.speed),
            onPressed: _testAllDelays,
            tooltip: _isTestingDelays ? 'Stop Testing' : 'Test All Delays',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed:
                () => showModalBottomSheet(
                  context: context,
                  builder:
                      (context) => AddMenu(
                        onImportClipboard: _importFromClipboard,
                        onAddSubscription: _addSubscription,
                        onScanQr: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'QR Scanner not implemented in this demo',
                              ),
                            ),
                          );
                        },
                      ),
                ),
          ),
          IconButton(
            icon: const Icon(Icons.article),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LogViewerPage(),
                  ),
                ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'clear') {
                _storageService.clearAll().then((_) => _loadData());
              } else if (value == 'mode') {
                final newValue = !_proxyOnly;
                await _storageService.saveProxyOnly(newValue);
                setState(() => _proxyOnly = newValue);
              } else if (value == 'bypass') {
                _editBypassSubnets();
              } else if (value == 'more') {
                showModalBottomSheet(
                  context: context,
                  builder:
                      (context) => OverflowMenu(
                        onUpdateSubscriptions: () async {
                          for (final sub in _subscriptions) {
                            await _updateSubscription(sub);
                          }
                        },
                        onDeleteAllServers: () async {
                          await _storageService.saveServers([]);
                          await _loadData();
                        },
                        onTestAllDelays: _testAllDelays,
                        onExportConfigs: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Export not implemented'),
                            ),
                          );
                        },
                      ),
                );
              }
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'mode',
                    child: Text(
                      _proxyOnly
                          ? 'Switch to VPN Mode'
                          : 'Switch to Proxy Mode',
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'bypass',
                    child: Text('Bypass Subnets'),
                  ),
                  const PopupMenuItem(
                    value: 'more',
                    child: Text('More Settings'),
                  ),
                  const PopupMenuItem(
                    value: 'clear',
                    child: Text('Clear All Data'),
                  ),
                ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child:
                _tabController != null
                    ? TabBarView(
                      controller: _tabController,
                      children: [
                        _buildServerList(_allServers),
                        ..._subscriptions.map(
                          (sub) => _buildServerList(
                            _allServers
                                .where((s) => s.subscriptionId == sub.id)
                                .toList(),
                            subscription: sub,
                          ),
                        ),
                      ],
                    )
                    : const Center(child: Text('No tabs')),
          ),
          _buildStatusPanel(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_v2rayStatus.value.state == 'CONNECTED') {
            _v2ray.stopV2Ray();
          } else {
            _connect();
          }
        },
        child: ValueListenableBuilder(
          valueListenable: _v2rayStatus,
          builder: (context, status, _) {
            return Icon(
              status.state == 'CONNECTED' ? Icons.stop : Icons.play_arrow,
            );
          },
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        height: 50,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (_coreVersion != null)
              Text('Core: $_coreVersion', style: const TextStyle(fontSize: 10)),
            if (_isTestingDelays) ...[
              const SizedBox(width: 10),
              const SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 10),
              ValueListenableBuilder<int>(
                valueListenable: _testedCountNotifier,
                builder: (context, tested, _) {
                  return ValueListenableBuilder<int>(
                    valueListenable: _totalToTestNotifier,
                    builder: (context, total, _) {
                      return Text(
                        'Testing latency... [$tested/$total]',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildServerList(
    List<ServerConfig> servers, {
    Subscription? subscription,
  }) {
    if (servers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No servers found'),
            if (subscription != null)
              ElevatedButton(
                onPressed: () => _updateSubscription(subscription),
                child: const Text('Update Subscription'),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (subscription != null) {
          await _updateSubscription(subscription);
        } else {
          await _loadData();
        }
      },
      child: ListView.builder(
        itemCount: servers.length,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: true,
        cacheExtent: 1000,
        itemBuilder: (context, index) {
          final server = servers[index];
          return ServerListItem(
            key: ValueKey(server.id),
            server: server,
            isSelected: _selectedServerId == server.id,
            onTap: () {
              setState(() => _selectedServerId = server.id);
              _storageService.saveSelectedServer(server.id);
            },
            onDelete: () async {
              await _storageService.removeServer(server.id);
              _loadData();
            },
            onTestDelay: () => _testDelay(server),
            onEdit: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit not implemented')),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusPanel() {
    return ValueListenableBuilder(
      valueListenable: _v2rayStatus,
      builder: (context, status, _) {
        if (status.state == 'DISCONNECTED' || status.state == 'STOPPED') {
          return const SizedBox.shrink();
        }
        return Container(
          padding: const EdgeInsets.all(8.0),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    Icons.arrow_upward,
                    _formatSpeed(status.uploadSpeed),
                    '↑',
                  ),
                  _buildStatItem(
                    Icons.arrow_downward,
                    _formatSpeed(status.downloadSpeed),
                    '↓',
                  ),
                  Text(
                    status.duration,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Total: ${_formatBytes(status.upload)} ↑ / ${_formatBytes(status.download)} ↓',
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatSpeed(int bytesPerSecond) {
    if (bytesPerSecond < 1024) {
      return '$bytesPerSecond B/s';
    }
    if (bytesPerSecond < 1024 * 1024) {
      return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    }
    return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Widget _buildStatItem(IconData icon, String value, String unit) {
    return Row(
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(fontSize: 12)),
        Text(unit, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
