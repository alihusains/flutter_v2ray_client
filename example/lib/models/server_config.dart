import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Represents a V2Ray server configuration.
class ServerConfig {
  /// Unique identifier for the server.
  final String id;

  /// Original share URL (vmess://, vless://, etc.).
  final String url;

  /// Server display name/remark.
  final String remark;

  /// Protocol type (vmess, vless, trojan, shadowsocks, socks).
  final String protocol;

  /// Server address.
  final String address;

  /// Server port.
  final int port;

  /// Full V2Ray JSON configuration.
  final String fullConfig;

  /// Subscription ID this server belongs to (null for manually added).
  final String? subscriptionId;

  /// Last measured delay in ms (-1 if not tested, -2 if timeout/error).
  /// Wrapped in a ValueNotifier for localized UI updates.
  final ValueNotifier<int> delayNotifier;

  /// Whether this server is currently being tested.
  final ValueNotifier<bool> isTestingNotifier;

  int get delay => delayNotifier.value;
  set delay(int value) => delayNotifier.value = value;

  bool get isTesting => isTestingNotifier.value;
  set isTesting(bool value) => isTestingNotifier.value = value;

  /// Creates a new server configuration.
  ServerConfig({
    required this.id,
    required this.url,
    required this.remark,
    required this.protocol,
    required this.address,
    required this.port,
    required this.fullConfig,
    this.subscriptionId,
    int delay = -1,
    bool isTesting = false,
  })  : delayNotifier = ValueNotifier<int>(delay),
        isTestingNotifier = ValueNotifier<bool>(isTesting);

  /// Creates a ServerConfig from JSON map.
  factory ServerConfig.fromJson(Map<String, dynamic> json) {
    return ServerConfig(
      id: json['id'] as String,
      url: json['url'] as String,
      remark: json['remark'] as String,
      protocol: json['protocol'] as String,
      address: json['address'] as String,
      port: json['port'] as int,
      fullConfig: json['fullConfig'] as String,
      subscriptionId: json['subscriptionId'] as String?,
      delay: json['delay'] as int? ?? -1,
    );
  }

  /// Converts the ServerConfig to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'remark': remark,
      'protocol': protocol,
      'address': address,
      'port': port,
      'fullConfig': fullConfig,
      'subscriptionId': subscriptionId,
      'delay': delay,
    };
  }

  /// Creates a copy of this ServerConfig with the given fields replaced.
  ServerConfig copyWith({
    String? id,
    String? url,
    String? remark,
    String? protocol,
    String? address,
    int? port,
    String? fullConfig,
    String? subscriptionId,
    int? delay,
    bool? isTesting,
  }) {
    return ServerConfig(
      id: id ?? this.id,
      url: url ?? this.url,
      remark: remark ?? this.remark,
      protocol: protocol ?? this.protocol,
      address: address ?? this.address,
      port: port ?? this.port,
      fullConfig: fullConfig ?? this.fullConfig,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      delay: delay ?? this.delay,
      isTesting: isTesting ?? this.isTesting,
    );
  }

  /// Returns the protocol name in uppercase for display.
  String get protocolDisplay => protocol.toUpperCase();

  /// Encodes a list of ServerConfigs to JSON string.
  static String encodeList(List<ServerConfig> servers) {
    return jsonEncode(servers.map((s) => s.toJson()).toList());
  }

  /// Decodes a JSON string to a list of ServerConfigs.
  static List<ServerConfig> decodeList(String jsonString) {
    final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
    return jsonList
        .map((json) => ServerConfig.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  void dispose() {
    delayNotifier.dispose();
    isTestingNotifier.dispose();
  }
}
