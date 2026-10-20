class CacheEntry<T> {
  final T data;
  final DateTime expiry;

  CacheEntry(this.data, this.expiry);

  bool get isExpired => DateTime.now().isAfter(expiry);
}

/// In-memory cache with TTL for search queries, anime details, and episodes.
class MetadataCache {
  static const Duration searchTtl = Duration(minutes: 5);
  static const Duration detailTtl = Duration(hours: 24);

  final Map<String, CacheEntry<dynamic>> _cache = {};

  void set<T>(String key, T value, Duration ttl) {
    _cache[key] = CacheEntry<T>(value, DateTime.now().add(ttl));
  }

  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    return entry.data as T?;
  }

  /// Returns cached data even if TTL expired, useful for offline and network failure fallback.
  T? getStale<T>(String key) {
    final entry = _cache[key];
    return entry?.data as T?;
  }

  void clear() {
    _cache.clear();
  }
}
