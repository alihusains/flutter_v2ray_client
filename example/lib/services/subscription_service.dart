import 'dart:convert';

import 'package:flutter_v2ray_client/flutter_v2ray.dart';
import 'package:http/http.dart' as http;

import '../models/server_config.dart';
import '../models/subscription.dart';

/// Service for fetching and parsing V2Ray subscription URLs.
class SubscriptionService {
  /// Supported protocol prefixes.
  static const List<String> supportedProtocols = [
    'vmess://',
    'vless://',
    'trojan://',
    'ss://',
    'socks://',
  ];

  /// Fetches a subscription URL and returns parsed servers.
  ///
  /// [subscription] - The subscription to fetch.
  /// Returns a list of parsed ServerConfig objects.
  Future<List<ServerConfig>> fetchSubscription(Subscription subscription) async {
    try {
      final response = await http.get(
        Uri.parse(subscription.url),
        headers: {
          'User-Agent': 'Flutter-V2Ray-Client/1.0',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch subscription: ${response.statusCode}');
      }

      final content = response.body.trim();
      return parseSubscriptionContent(content, subscription.id);
    } catch (e) {
      throw Exception('Failed to fetch subscription: $e');
    }
  }

  /// Parses subscription content (auto-detects base64 or plain text).
  ///
  /// [content] - The raw subscription content.
  /// [subscriptionId] - The subscription ID to assign to parsed servers.
  /// Returns a list of parsed ServerConfig objects.
  List<ServerConfig> parseSubscriptionContent(
    String content,
    String subscriptionId,
  ) {
    String decodedContent = content;

    // Try to decode as base64 if it doesn't look like URLs
    if (!_looksLikeUrls(content)) {
      try {
        // Remove any whitespace and try base64 decode
        var cleanContent = content.replaceAll(RegExp(r'\s'), '');
        // Pad base64 if needed
        while (cleanContent.length % 4 != 0) {
          cleanContent += '=';
        }
        decodedContent = utf8.decode(base64Decode(cleanContent));
      } catch (_) {
        // If base64 decode fails, use original content
        decodedContent = content;
      }
    }

    return _parseUrls(decodedContent, subscriptionId);
  }

  /// Parses a single V2Ray URL and returns a ServerConfig.
  ///
  /// [url] - The V2Ray share URL.
  /// [subscriptionId] - Optional subscription ID.
  /// Returns a ServerConfig or null if parsing fails.
  ServerConfig? parseUrl(String url, {String? subscriptionId}) {
    final trimmedUrl = url.trim();
    if (trimmedUrl.isEmpty) return null;

    final protocol = _getProtocol(trimmedUrl);
    if (protocol == null) return null;

    try {
      final v2rayUrl = V2ray.parseFromURL(trimmedUrl);
      return ServerConfig(
        id: _generateId(),
        url: trimmedUrl,
        remark: v2rayUrl.remark.isNotEmpty ? v2rayUrl.remark : 'Unknown',
        protocol: protocol,
        address: v2rayUrl.address,
        port: v2rayUrl.port,
        fullConfig: v2rayUrl.getFullConfiguration(),
        subscriptionId: subscriptionId,
      );
    } catch (_) {
      return null;
    }
  }

  /// Checks if content looks like URL list (not base64).
  bool _looksLikeUrls(String content) {
    final lines = content.split('\n').where((l) => l.trim().isNotEmpty);
    if (lines.isEmpty) return false;

    // Check if any line starts with a supported protocol
    for (final line in lines.take(5)) {
      final trimmed = line.trim().toLowerCase();
      for (final protocol in supportedProtocols) {
        if (trimmed.startsWith(protocol)) {
          return true;
        }
      }
      // Also check for comment lines (common in subscription files)
      if (trimmed.startsWith('#')) {
        continue;
      }
    }
    return false;
  }

  /// Parses URLs from decoded content.
  List<ServerConfig> _parseUrls(String content, String subscriptionId) {
    final servers = <ServerConfig>[];
    final lines = content.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();
      // Skip empty lines and comments
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

      final server = parseUrl(trimmed, subscriptionId: subscriptionId);
      if (server != null) {
        servers.add(server);
      }
    }

    return servers;
  }

  /// Gets the protocol from a URL.
  String? _getProtocol(String url) {
    final lowercaseUrl = url.toLowerCase();
    if (lowercaseUrl.startsWith('vmess://')) return 'vmess';
    if (lowercaseUrl.startsWith('vless://')) return 'vless';
    if (lowercaseUrl.startsWith('trojan://')) return 'trojan';
    if (lowercaseUrl.startsWith('ss://')) return 'shadowsocks';
    if (lowercaseUrl.startsWith('socks://')) return 'socks';
    return null;
  }

  /// Generates a unique ID.
  String _generateId() {
    return '${DateTime.now().microsecondsSinceEpoch}_${(DateTime.now().millisecond * 1000).toRadixString(36)}';
  }
}
