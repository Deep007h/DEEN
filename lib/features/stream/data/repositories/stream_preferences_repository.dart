import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../settings/domain/models/app_settings.dart';
import '../../domain/models/quality_option.dart';

/// Manages and persists user preferences for audio language (sub/dub),
/// subtitle track selection, and video quality both globally and per-anime.
class StreamPreferencesRepository {
  final SharedPreferences _prefs;
  final AppSettings? settings;

  const StreamPreferencesRepository(this._prefs, {this.settings});

  static const _kGlobalAudio = 'stream_pref_global_audio';
  static const _kGlobalSubtitle = 'stream_pref_global_subtitle';
  static const _kGlobalQuality = 'stream_pref_global_quality';
  static const _kAppSettingsKey = 'app_settings_v1';

  static const _kAnimeAudioPrefix = 'stream_pref_anime_audio_';
  static const _kAnimeSubtitlePrefix = 'stream_pref_anime_sub_';
  static const _kAnimeQualityPrefix = 'stream_pref_anime_quality_';

  // -------------------------------------------------------------
  // Audio Preferences (Original vs Dubs)
  // -------------------------------------------------------------

  String getGlobalAudioLanguage() {
    if (settings != null) {
      final audio = settings!.defaultAudioLanguage.toLowerCase();
      if (audio.contains('eng')) return 'en';
      if (audio.contains('jap') || audio.contains('orig')) return 'ja';
    }

    final direct = _prefs.getString(_kGlobalAudio);
    if (direct != null && direct.isNotEmpty) return direct;

    final appSettingsRaw = _prefs.getString(_kAppSettingsKey);
    if (appSettingsRaw != null && appSettingsRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(appSettingsRaw) as Map<String, dynamic>;
        final audio = decoded['defaultAudioLanguage'] as String?;
        if (audio != null) {
          final lower = audio.toLowerCase();
          if (lower.contains('eng')) return 'en';
          if (lower.contains('jap') || lower.contains('orig')) return 'ja';
        }
      } catch (_) {}
    }

    return 'ja';
  }

  Future<void> setGlobalAudioLanguage(String code) =>
      _prefs.setString(_kGlobalAudio, code);

  String getEffectiveAudioLanguage(int animeId) {
    final perAnime = _prefs.getString('$_kAnimeAudioPrefix$animeId');
    return perAnime ?? getGlobalAudioLanguage();
  }

  Future<void> setAnimeAudioLanguage(int animeId, String code) =>
      _prefs.setString('$_kAnimeAudioPrefix$animeId', code);

  // -------------------------------------------------------------
  // Subtitle Preferences
  // -------------------------------------------------------------

  String getGlobalSubtitleLanguage() {
    if (settings != null) {
      final sub = settings!.defaultSubtitleLanguage.toLowerCase();
      if (sub == 'off') return 'off';
      if (sub.contains('span')) return 'es';
      if (sub.contains('eng')) return 'en';
    }

    final direct = _prefs.getString(_kGlobalSubtitle);
    if (direct != null && direct.isNotEmpty) return direct;

    final appSettingsRaw = _prefs.getString(_kAppSettingsKey);
    if (appSettingsRaw != null && appSettingsRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(appSettingsRaw) as Map<String, dynamic>;
        final sub = decoded['defaultSubtitleLanguage'] as String?;
        if (sub != null) {
          final lower = sub.toLowerCase();
          if (lower == 'off') return 'off';
          if (lower.contains('span')) return 'es';
          if (lower.contains('eng')) return 'en';
        }
      } catch (_) {}
    }

    return 'en';
  }

  Future<void> setGlobalSubtitleLanguage(String code) =>
      _prefs.setString(_kGlobalSubtitle, code);

  String getEffectiveSubtitleLanguage(int animeId) {
    final perAnime = _prefs.getString('$_kAnimeSubtitlePrefix$animeId');
    return perAnime ?? getGlobalSubtitleLanguage();
  }

  Future<void> setAnimeSubtitleLanguage(int animeId, String code) =>
      _prefs.setString('$_kAnimeSubtitlePrefix$animeId', code);

  // -------------------------------------------------------------
  // Quality Preferences
  // -------------------------------------------------------------

  String getGlobalQuality() {
    if (settings != null && settings!.defaultQuality.isNotEmpty) {
      return settings!.defaultQuality;
    }

    final direct = _prefs.getString(_kGlobalQuality);
    if (direct != null && direct.isNotEmpty) return direct;

    final appSettingsRaw = _prefs.getString(_kAppSettingsKey);
    if (appSettingsRaw != null && appSettingsRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(appSettingsRaw) as Map<String, dynamic>;
        final q = decoded['defaultQuality'] as String?;
        if (q != null && q.isNotEmpty) return q;
      } catch (_) {}
    }

    return 'Auto';
  }

  Future<void> setGlobalQuality(String qualityLabel) =>
      _prefs.setString(_kGlobalQuality, qualityLabel);

  String getEffectiveQuality(int animeId) {
    final perAnime = _prefs.getString('$_kAnimeQualityPrefix$animeId');
    return perAnime ?? getGlobalQuality();
  }

  Future<void> setAnimeQuality(int animeId, String qualityLabel) =>
      _prefs.setString('$_kAnimeQualityPrefix$animeId', qualityLabel);

  /// Picks the closest available [QualityOption] based on the user's preferred label.
  static QualityOption pickClosestQuality(
    List<QualityOption> available,
    String preferredLabel,
  ) {
    if (available.isEmpty) return QualityOption.auto();

    if (preferredLabel.toLowerCase().startsWith('auto')) {
      return available.firstWhere((q) => q.isAuto, orElse: () => available.first);
    }

    // Try exact label match
    final exact = available.where((q) => q.label.toLowerCase() == preferredLabel.toLowerCase());
    if (exact.isNotEmpty) return exact.first;

    // Parse target height (e.g. "1080p" -> 1080)
    final targetHeight = int.tryParse(preferredLabel.replaceAll(RegExp(r'\D'), ''));
    if (targetHeight == null) {
      return available.firstWhere((q) => q.isAuto, orElse: () => available.first);
    }

    // Filter non-auto options with height
    final nonAuto = available.where((q) => !q.isAuto && q.height != null).toList();
    if (nonAuto.isEmpty) return available.first;

    QualityOption closest = nonAuto.first;
    int minDiff = (closest.height! - targetHeight).abs();

    for (final opt in nonAuto) {
      final diff = (opt.height! - targetHeight).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = opt;
      }
    }

    return closest;
  }
}
