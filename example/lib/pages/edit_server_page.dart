import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_v2ray_client/flutter_v2ray.dart';
import '../models/server_config.dart';

class EditServerPage extends StatefulWidget {
  final ServerConfig server;

  const EditServerPage({super.key, required this.server});

  @override
  State<EditServerPage> createState() => _EditServerPageState();
}

class _EditServerPageState extends State<EditServerPage> {
  late TextEditingController _remarkController;
  late TextEditingController _addressController;
  late TextEditingController _portController;
  late TextEditingController _urlController;
  late TextEditingController _uuidController;
  late TextEditingController _pathController;
  late TextEditingController _sniController;
  String _protocol = '';

  @override
  void initState() {
    super.initState();
    _remarkController = TextEditingController(text: widget.server.remark);
    _addressController = TextEditingController(text: widget.server.address);
    _portController = TextEditingController(text: widget.server.port.toString());
    _urlController = TextEditingController(text: widget.server.url);
    _uuidController = TextEditingController();
    _pathController = TextEditingController();
    _sniController = TextEditingController();
    _protocol = widget.server.protocol;
    _parseUrlToFields(widget.server.url, initial: true);
  }

  void _parseUrlToFields(String url, {bool initial = false}) {
    try {
      final v2rayUrl = V2ray.parseFromURL(url);
      if (!initial) {
        setState(() {
          _remarkController.text = v2rayUrl.remark;
          _addressController.text = v2rayUrl.address;
          _portController.text = v2rayUrl.port.toString();
          _protocol = url.split('://')[0].toLowerCase();
        });
      }

      if (v2rayUrl is VmessURL) {
        _uuidController.text = v2rayUrl.rawConfig['id'] ?? '';
        _pathController.text = v2rayUrl.rawConfig['path'] ?? '';
        _sniController.text = v2rayUrl.rawConfig['sni'] ?? v2rayUrl.rawConfig['host'] ?? '';
      } else if (v2rayUrl is VlessURL) {
        _uuidController.text = v2rayUrl.uri.userInfo;
        _pathController.text = v2rayUrl.uri.queryParameters['path'] ?? '';
        _sniController.text = v2rayUrl.uri.queryParameters['sni'] ?? v2rayUrl.uri.queryParameters['host'] ?? '';
      } else if (v2rayUrl is TrojanURL) {
        _uuidController.text = v2rayUrl.uri.userInfo;
        _pathController.text = v2rayUrl.uri.queryParameters['path'] ?? '';
        _sniController.text = v2rayUrl.uri.queryParameters['sni'] ?? v2rayUrl.uri.queryParameters['host'] ?? '';
      } else if (v2rayUrl is ShadowSocksURL) {
        _uuidController.text = '${v2rayUrl.method}:${v2rayUrl.password}';
        _pathController.text = v2rayUrl.uri.queryParameters['path'] ?? '';
        _sniController.text = v2rayUrl.uri.queryParameters['sni'] ?? v2rayUrl.uri.queryParameters['host'] ?? '';
      } else if (v2rayUrl is SocksURL) {
        _uuidController.text = '${v2rayUrl.username ?? ''}:${v2rayUrl.password ?? ''}';
      }
    } catch (e) {
      // ignore
    }
  }

  @override
  void dispose() {
    _remarkController.dispose();
    _addressController.dispose();
    _portController.dispose();
    _urlController.dispose();
    _uuidController.dispose();
    _pathController.dispose();
    _sniController.dispose();
    super.dispose();
  }

  void _save() {
    final String newUrl = _urlController.text.trim();
    if (newUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL cannot be empty')),
      );
      return;
    }

    try {
      final v2rayUrl = V2ray.parseFromURL(newUrl);
      final newServer = widget.server.copyWith(
        url: newUrl,
        remark: v2rayUrl.remark.isNotEmpty ? v2rayUrl.remark : _remarkController.text,
        address: v2rayUrl.address.isNotEmpty ? v2rayUrl.address : _addressController.text,
        port: v2rayUrl.port > 0 ? v2rayUrl.port : int.tryParse(_portController.text) ?? 443,
        fullConfig: v2rayUrl.getFullConfiguration(),
        protocol: newUrl.split('://')[0].toLowerCase(),
      );

      Navigator.pop(context, newServer);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid config: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Server'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save',
            onPressed: _save,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Basic Information'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _remarkController,
              decoration: const InputDecoration(
                labelText: 'Remark / Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label_outline),
              ),
              onChanged: (value) => _tryUpdateUrl(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.dns_outlined),
                    ),
                    onChanged: (value) => _tryUpdateUrl(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _portController,
                    decoration: const InputDecoration(
                      labelText: 'Port',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _tryUpdateUrl(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _uuidController,
              decoration: InputDecoration(
                labelText: _protocol == 'ss' || _protocol == 'socks' ? 'Password / UserInfo' : 'UUID',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.vpn_key_outlined),
              ),
              onChanged: (value) => _tryUpdateUrl(),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Advanced Settings (Transport & TLS)'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _pathController,
                    decoration: const InputDecoration(
                      labelText: 'Path',
                      hintText: '/v2ray',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => _tryUpdateUrl(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _sniController,
                    decoration: const InputDecoration(
                      labelText: 'SNI / Host',
                      hintText: 'example.com',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => _tryUpdateUrl(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Source Configuration'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Share URL',
                border: OutlineInputBorder(),
                helperText: 'Editing this will automatically update the fields above.',
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              onChanged: (value) {
                _parseUrlToFields(value.trim());
              },
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.code),
              label: const Text('Preview V2Ray JSON'),
              onPressed: _showJsonPreview,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _showJsonPreview() {
    try {
      final v2rayUrl = V2ray.parseFromURL(_urlController.text.trim());
      final jsonConfig = v2rayUrl.getFullConfiguration();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('V2Ray JSON Preview'),
          content: SingleChildScrollView(
            child: SelectableText(
              jsonConfig,
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot generate JSON: $e')),
      );
    }
  }

  void _tryUpdateUrl() {
    final String currentUrl = _urlController.text.trim();
    if (currentUrl.isEmpty) return;

    try {
      String newUrl = currentUrl;
      final remark = _remarkController.text;
      final address = _addressController.text;
      final port = int.tryParse(_portController.text) ?? 0;
      final uuid = _uuidController.text;
      final path = _pathController.text;
      final sni = _sniController.text;

      if (_protocol == 'vmess') {
        final String base64Part = currentUrl.substring(8);
        String padded = base64Part;
        if (padded.length % 4 > 0) {
          padded += '=' * (4 - padded.length % 4);
        }
        try {
          final jsonString = utf8.decode(base64Decode(padded));
          final Map<String, dynamic> config = jsonDecode(jsonString);

          config['ps'] = remark;
          config['add'] = address;
          config['port'] = port;
          config['id'] = uuid;
          config['path'] = path;
          if (config['tls'] == 'tls') {
            config['sni'] = sni;
            config['host'] = sni;
          }

          final newJson = jsonEncode(config);
          final newBase64 = base64Encode(utf8.encode(newJson));
          newUrl = 'vmess://$newBase64';
        } catch (e) {}
      } else if (_protocol == 'ss') {
        final uri = Uri.parse(currentUrl);
        final query = Map<String, String>.from(uri.queryParameters);
        if (path.isNotEmpty) query['path'] = path;
        if (sni.isNotEmpty) query['sni'] = sni;

        // ShadowSocks userInfo is base64(method:password)
        String userInfo = uuid;
        if (!uuid.contains(':')) {
           // If user just entered password, we might lose method.
           // But usually they see "method:password" in the field.
        } else {
           userInfo = base64Encode(utf8.encode(uuid)).replaceAll('=', '');
        }

        newUrl = uri.replace(
          host: address,
          port: port,
          userInfo: userInfo,
          queryParameters: query,
          fragment: remark,
        ).toString();
      } else {
        final uri = Uri.parse(currentUrl);
        final query = Map<String, String>.from(uri.queryParameters);
        if (path.isNotEmpty) query['path'] = path;
        if (sni.isNotEmpty) {
          query['sni'] = sni;
          if (query['type'] == 'ws' || query['type'] == 'grpc') {
            query['host'] = sni;
          }
        }

        newUrl = uri.replace(
          host: address,
          port: port,
          userInfo: uuid,
          queryParameters: query,
          fragment: remark,
        ).toString();
      }

      if (newUrl != _urlController.text) {
        setState(() {
          _urlController.text = newUrl;
        });
      }
    } catch (e) {}
  }
}
