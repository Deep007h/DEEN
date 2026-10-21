class CacheEntry<T> {
  final T data;
  final DateTime expiry;

  CacheEntry(this.data, this.expiry);

  bool get isExpired => DateTime.now().isAfter(expiry);
}

/// In-memory bounded LRU cache with TTL for search queries, anime details, and episodes.
class MetadataCache {
  static const Duration searchTtl = Duration(minutes: 5);
  static const Duration detailTtl = Duration(hours: 24);
  static const int maxEntries = 150;

  final Map<String, CacheEntry<dynamic>> _cache = {};

  void set<T>(String key, T value, Duration ttl) {
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    } else if (_cache.length >= maxEntries) {
      // Evict oldest (first inserted in linked hash map)
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
    }
    _cache[key] = CacheEntry<T>(value, DateTime.now().add(ttl));
  }

  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    // Refresh LRU order on access
    _cache.remove(key);
    _cache[key] = entry;
    return entry.data as T?;
  }

  /// Returns cached data even if TTL expired, useful for offline and network failure fallback.
  T? getStale<T>(String key) {
    final entry = _cache[key];
    return entry?.data as T?;
  }

  int get size => _cache.length;

  void clear() {
    _cache.clear();
  }
}
