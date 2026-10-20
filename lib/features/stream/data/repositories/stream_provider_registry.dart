import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/stream_provider.dart';

/// Registry and configuration manager for stream providers.
/// Tracks registered providers, their enabled states, and user priority order.
class StreamProviderRegistry {
  final SharedPreferences _prefs;
  final Map<String, StreamProvider> _registered = {};

  StreamProviderRegistry(this._prefs, List<StreamProvider> providers) {
    for (final p in providers) {
      _registered[p.id] = p;
    }
  }

  static const _kPriorityOrder = 'stream_providers_priority_order';
  static const _kEnabledPrefix = 'stream_provider_enabled_';
  static const _kDirectUrlPattern = 'stream_direct_url_pattern';
  static const _kJellyfinHost = 'stream_jellyfin_host';
  static const _kJellyfinToken = 'stream_jellyfin_token';
  static const _kAnimeProviderPrefix = 'stream_anime_selected_provider_';

  List<StreamProvider> get allProviders => _registered.values.toList();

  StreamProvider? getProvider(String id) => _registered[id];

  /// Gets priority list of provider IDs.
  List<String> getPriorityOrder() {
    final saved = _prefs.getStringList(_kPriorityOrder);
    if (saved != null && saved.isNotEmpty) {
      // Include any newly registered providers not yet in saved order
      final current = List<String>.from(saved);
      for (final id in _registered.keys) {
        if (!current.contains(id)) current.add(id);
      }
      return current;
    }
    // Default order
    return ['megavid', 'demo', 'direct_url', 'jellyfin'];
  }

  Future<void> updatePriorityOrder(List<String> order) async {
    await _prefs.setStringList(_kPriorityOrder, order);
  }

  bool isProviderEnabled(String id) {
    final val = _prefs.getBool('$_kEnabledPrefix$id');
    if (val != null) return val;
    // Default: 'megavid' enabled out of the box. Demo is disabled by default.
    return id == 'megavid';
  }

  Future<void> setProviderEnabled(String id, bool enabled) async {
    await _prefs.setBool('$_kEnabledPrefix$id', enabled);
  }

  /// Returns enabled providers in priority order.
  List<StreamProvider> getOrderedEnabledProviders() {
    final order = getPriorityOrder();
    final result = <StreamProvider>[];
    for (final id in order) {
      if (isProviderEnabled(id)) {
        final p = _registered[id];
        if (p != null) result.add(p);
      }
    }
    // Fallback: if no providers are enabled, ensure megavid is available
    if (result.isEmpty && _registered.containsKey('megavid')) {
      result.add(_registered['megavid']!);
    } else if (result.isEmpty && _registered.isNotEmpty) {
      result.add(_registered.values.first);
    }
    return result;
  }

  // -------------------------------------------------------------
  // Per-Anime Provider Selection (from Detail screen's "Source" chip)
  // -------------------------------------------------------------

  String? getAnimeSelectedProviderId(int animeId) =>
      _prefs.getString('$_kAnimeProviderPrefix$animeId');

  Future<void> setAnimeSelectedProviderId(int animeId, String providerId) =>
      _prefs.setString('$_kAnimeProviderPrefix$animeId', providerId);

  // -------------------------------------------------------------
  // Provider Specific Configs
  // -------------------------------------------------------------

  String getDirectUrlPattern() =>
      _prefs.getString(_kDirectUrlPattern) ??
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';

  Future<void> setDirectUrlPattern(String pattern) =>
      _prefs.setString(_kDirectUrlPattern, pattern);

  String getJellyfinHost() => _prefs.getString(_kJellyfinHost) ?? '';

  Future<void> setJellyfinHost(String host) =>
      _prefs.setString(_kJellyfinHost, host);

  String getJellyfinToken() => _prefs.getString(_kJellyfinToken) ?? '';

  Future<void> setJellyfinToken(String token) =>
      _prefs.setString(_kJellyfinToken, token);
}
