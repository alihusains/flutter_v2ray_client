import 'dart:convert';

/// Represents a V2Ray subscription.
class Subscription {
  /// Unique identifier for the subscription.
  final String id;

  /// Subscription URL.
  final String url;

  /// Display name for the subscription.
  final String name;

  /// Last update timestamp.
  final DateTime? lastUpdated;

  /// Number of servers in this subscription.
  int serverCount;

  /// Creates a new subscription.
  Subscription({
    required this.id,
    required this.url,
    required this.name,
    this.lastUpdated,
    this.serverCount = 0,
  });

  /// Creates a Subscription from JSON map.
  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      url: json['url'] as String,
      name: json['name'] as String,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : null,
      serverCount: json['serverCount'] as int? ?? 0,
    );
  }

  /// Converts the Subscription to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'name': name,
      'lastUpdated': lastUpdated?.toIso8601String(),
      'serverCount': serverCount,
    };
  }

  /// Creates a copy of this Subscription with the given fields replaced.
  Subscription copyWith({
    String? id,
    String? url,
    String? name,
    DateTime? lastUpdated,
    int? serverCount,
  }) {
    return Subscription(
      id: id ?? this.id,
      url: url ?? this.url,
      name: name ?? this.name,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      serverCount: serverCount ?? this.serverCount,
    );
  }

  /// Encodes a list of Subscriptions to JSON string.
  static String encodeList(List<Subscription> subscriptions) {
    return jsonEncode(subscriptions.map((s) => s.toJson()).toList());
  }

  /// Decodes a JSON string to a list of Subscriptions.
  static List<Subscription> decodeList(String jsonString) {
    final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
    return jsonList
        .map((json) => Subscription.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
