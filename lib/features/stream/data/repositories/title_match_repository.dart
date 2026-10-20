import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/source_match.dart';

/// Persists user-confirmed catalog matches per anime and provider.
class TitleMatchRepository {
  final SharedPreferences _prefs;

  const TitleMatchRepository(this._prefs);

  static const _prefix = 'stream_title_match_';

  String _key(int animeId, String providerId) => '$_prefix${animeId}_$providerId';

  /// Gets the user's saved manual match for an anime and provider.
  SourceMatch? getSavedMatch(int animeId, String providerId) {
    final raw = _prefs.getString(_key(animeId, providerId));
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return SourceMatch.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// Saves or updates the manual match selection.
  Future<void> saveMatch(int animeId, String providerId, SourceMatch match) async {
    final raw = jsonEncode(match.toJson());
    await _prefs.setString(_key(animeId, providerId), raw);
  }

  /// Clears a saved match so the fuzzy matcher is used again.
  Future<void> clearMatch(int animeId, String providerId) async {
    await _prefs.remove(_key(animeId, providerId));
  }
}
