class CacheEntry {
  final String key;
  final dynamic data;
  final DateTime accessTime;
  final DateTime expiryTime;

  // Runtime pointers for the Doubly Linked List (NOT saved to disk)
  CacheEntry? prev;
  CacheEntry? next;

  CacheEntry({
    required this.key,
    required this.data,
    DateTime? accessTime,
    DateTime? expiryTime,
  }) : accessTime = accessTime ?? DateTime.now(),
       expiryTime = expiryTime ?? DateTime.now().add(const Duration(days: 30));

  /// Converts the entry to a JSON-compatible Map for storage
  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'data': data, // Assumes 'data' is a basic type or Map (JSON encodable)
      'accessTime': accessTime.toIso8601String(),
      'expiryTime': expiryTime.toIso8601String(),
    };
  }

  /// Creates a CacheEntry from a stored Map
  factory CacheEntry.fromJson(Map<String, dynamic> json) {
    // 1. Safety Check: If critical fields are missing, throw a clean error
    if (json['key'] == null ||
        json['accessTime'] == null ||
        json['expiryTime'] == null) {
      throw const FormatException("Cache file is corrupt or missing fields.");
    }

    return CacheEntry(
      key: json['key'] as String,
      data: json['data'],
      accessTime: DateTime.parse(json['accessTime'] as String),
      expiryTime: DateTime.parse(json['expiryTime'] as String),
    );
  }
}
