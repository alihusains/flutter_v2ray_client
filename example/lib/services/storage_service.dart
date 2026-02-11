import 'package:shared_preferences/shared_preferences.dart';

import '../models/server_config.dart';
import '../models/subscription.dart';

/// Service for storing and retrieving data using SharedPreferences.
class StorageService {
  static const String _serversKey = 'v2ray_servers';
  static const String _subscriptionsKey = 'v2ray_subscriptions';
  static const String _selectedServerKey = 'v2ray_selected_server';

  SharedPreferences? _prefs;

  /// Initializes the storage service.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Ensures preferences are initialized.
  Future<SharedPreferences> get _preferences async {
    if (_prefs == null) {
      await init();
    }
    return _prefs!;
  }

  // ==================== Servers ====================

  /// Saves the list of servers.
  Future<void> saveServers(List<ServerConfig> servers) async {
    final prefs = await _preferences;
    await prefs.setString(_serversKey, ServerConfig.encodeList(servers));
  }

  /// Loads the list of servers.
  Future<List<ServerConfig>> loadServers() async {
    final prefs = await _preferences;
    final jsonString = prefs.getString(_serversKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    try {
      return ServerConfig.decodeList(jsonString);
    } catch (_) {
      return [];
    }
  }

  /// Adds a server to the list.
  Future<void> addServer(ServerConfig server) async {
    final servers = await loadServers();
    servers.add(server);
    await saveServers(servers);
  }

  /// Removes a server by ID.
  Future<void> removeServer(String id) async {
    final servers = await loadServers();
    servers.removeWhere((s) => s.id == id);
    await saveServers(servers);
  }

  /// Updates a server.
  Future<void> updateServer(ServerConfig server) async {
    final servers = await loadServers();
    final index = servers.indexWhere((s) => s.id == server.id);
    if (index != -1) {
      servers[index] = server;
      await saveServers(servers);
    }
  }

  /// Removes all servers for a subscription.
  Future<void> removeServersBySubscription(String subscriptionId) async {
    final servers = await loadServers();
    servers.removeWhere((s) => s.subscriptionId == subscriptionId);
    await saveServers(servers);
  }

  /// Gets servers by subscription ID (null for manually added).
  Future<List<ServerConfig>> getServersBySubscription(
    String? subscriptionId,
  ) async {
    final servers = await loadServers();
    return servers.where((s) => s.subscriptionId == subscriptionId).toList();
  }

  // ==================== Subscriptions ====================

  /// Saves the list of subscriptions.
  Future<void> saveSubscriptions(List<Subscription> subscriptions) async {
    final prefs = await _preferences;
    await prefs.setString(
      _subscriptionsKey,
      Subscription.encodeList(subscriptions),
    );
  }

  /// Loads the list of subscriptions.
  Future<List<Subscription>> loadSubscriptions() async {
    final prefs = await _preferences;
    final jsonString = prefs.getString(_subscriptionsKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    try {
      return Subscription.decodeList(jsonString);
    } catch (_) {
      return [];
    }
  }

  /// Adds a subscription.
  Future<void> addSubscription(Subscription subscription) async {
    final subscriptions = await loadSubscriptions();
    subscriptions.add(subscription);
    await saveSubscriptions(subscriptions);
  }

  /// Removes a subscription by ID.
  Future<void> removeSubscription(String id) async {
    final subscriptions = await loadSubscriptions();
    subscriptions.removeWhere((s) => s.id == id);
    await saveSubscriptions(subscriptions);
    // Also remove all servers for this subscription
    await removeServersBySubscription(id);
  }

  /// Updates a subscription.
  Future<void> updateSubscription(Subscription subscription) async {
    final subscriptions = await loadSubscriptions();
    final index = subscriptions.indexWhere((s) => s.id == subscription.id);
    if (index != -1) {
      subscriptions[index] = subscription;
      await saveSubscriptions(subscriptions);
    }
  }

  // ==================== Selected Server ====================

  /// Saves the selected server ID.
  Future<void> saveSelectedServer(String? serverId) async {
    final prefs = await _preferences;
    if (serverId == null) {
      await prefs.remove(_selectedServerKey);
    } else {
      await prefs.setString(_selectedServerKey, serverId);
    }
  }

  /// Loads the selected server ID.
  Future<String?> loadSelectedServer() async {
    final prefs = await _preferences;
    return prefs.getString(_selectedServerKey);
  }

  // ==================== Clear ====================

  /// Clears all stored data.
  Future<void> clearAll() async {
    final prefs = await _preferences;
    await prefs.remove(_serversKey);
    await prefs.remove(_subscriptionsKey);
    await prefs.remove(_selectedServerKey);
  }
}
