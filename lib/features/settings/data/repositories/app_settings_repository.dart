import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../metadata/domain/models/anime_titles.dart';
import '../../../stream/domain/models/audio_language.dart';
import '../../domain/models/app_settings.dart';

/// Global shared preferences provider, initialized in main() before runApp().
final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);

/// Repository managing user settings persistence in SharedPreferences.
class AppSettingsRepository {
  static const String _key = 'app_settings_v1';
  final SharedPreferences? _prefs;
  SharedPreferencesAsync? _asyncPrefs;

  AppSettingsRepository([this._prefs]);

  SharedPreferencesAsync get _getAsyncPrefs {
    _asyncPrefs ??= SharedPreferencesAsync();
    return _asyncPrefs!;
  }

  AppSettings loadSettingsSync() {
    final p = _prefs;
    if (p == null) return const AppSettings();

    try {
      final raw = p.getString(_key);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        return AppSettings.fromJson(decoded);
      }
    } catch (_) {}
    return const AppSettings();
  }

  Future<AppSettings> loadSettings() async {
    final syncSettings = loadSettingsSync();
    if (syncSettings != const AppSettings()) {
      return syncSettings;
    }

    try {
      final raw = await _getAsyncPrefs.getString(_key);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        return AppSettings.fromJson(decoded);
      }
    } catch (_) {}

    return const AppSettings();
  }

  Future<void> saveSettings(AppSettings settings) async {
    final raw = jsonEncode(settings.toJson());

    try {
      await _getAsyncPrefs.setString(_key, raw);
    } catch (_) {}

    if (_prefs != null) {
      try {
        await _prefs.setString(_key, raw);
      } catch (_) {}
    }

    await syncStreamPreferences(settings);
  }

  Future<void> syncStreamPreferences(AppSettings settings) async {
    final primaryAudioCode = AudioLanguage.fromName(settings.defaultAudioLanguage).code;
    final secondaryAudioCode = AudioLanguage.fromName(settings.secondaryAudioLanguage).code;
    final qualityLabel = settings.defaultQuality;
    final subLower = settings.defaultSubtitleLanguage.toLowerCase();
    final subCode = subLower == 'off' ? 'off' : (subLower.contains('span') ? 'es' : 'en');

    try {
      await _getAsyncPrefs.setString('stream_pref_global_audio', primaryAudioCode);
      await _getAsyncPrefs.setString('stream_pref_global_secondary_audio', secondaryAudioCode);
      await _getAsyncPrefs.setString('stream_pref_global_quality', qualityLabel);
      await _getAsyncPrefs.setString('stream_pref_global_subtitle', subCode);
    } catch (_) {}

    if (_prefs != null) {
      try {
        await _prefs.setString('stream_pref_global_audio', primaryAudioCode);
        await _prefs.setString('stream_pref_global_secondary_audio', secondaryAudioCode);
        await _prefs.setString('stream_pref_global_quality', qualityLabel);
        await _prefs.setString('stream_pref_global_subtitle', subCode);
      } catch (_) {}
    }
  }
}

/// Provider for [AppSettingsRepository].
final appSettingsRepositoryProvider = Provider<AppSettingsRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AppSettingsRepository(prefs);
});

/// StateNotifier managing and broadcasting changes to [AppSettings].
class AppSettingsNotifier extends StateNotifier<AppSettings> {
  final AppSettingsRepository _repo;
  bool _isLoaded = false;

  AppSettingsNotifier(this._repo) : super(_repo.loadSettingsSync()) {
    _load();
  }

  Future<void> _load() async {
    final loaded = await _repo.loadSettings();
    if (!_isLoaded) {
      _isLoaded = true;
      state = loaded;
      await _repo.saveSettings(loaded);
      await _repo.syncStreamPreferences(loaded);
    }
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    _isLoaded = true;
    state = newSettings;
    await _repo.saveSettings(newSettings);
  }

  Future<void> updateAccentColor(Color color) async {
    final updated = state.copyWith(accentColorValue: color.toARGB32());
    await updateSettings(updated);
  }

  Future<void> updateTitlePreference(TitlePreference pref) async {
    final updated = state.copyWith(titlePreference: pref);
    await updateSettings(updated);
  }

  Future<void> updateSkipStep(int seconds) async {
    final updated = state.copyWith(skipStepSeconds: seconds);
    await updateSettings(updated);
  }

  Future<void> updateLongPressSpeed(double speed) async {
    final updated = state.copyWith(longPressSpeed: speed);
    await updateSettings(updated);
  }

  Future<void> setGesturesEnabled(bool enabled) async {
    final updated = state.copyWith(gesturesEnabled: enabled);
    await updateSettings(updated);
  }

  Future<void> setAutoplayNext(bool autoplay) async {
    final updated = state.copyWith(autoplayNext: autoplay);
    await updateSettings(updated);
  }

  Future<void> updateDefaultQuality(String quality) async {
    final updated = state.copyWith(defaultQuality: quality);
    await updateSettings(updated);
  }

  Future<void> updateDefaultAudio(String audio) async {
    final updated = state.copyWith(defaultAudioLanguage: audio);
    await updateSettings(updated);
  }

  Future<void> updateSecondaryAudio(String audio) async {
    final updated = state.copyWith(secondaryAudioLanguage: audio);
    await updateSettings(updated);
  }

  Future<void> updateDefaultSubtitle(String sub) async {
    final updated = state.copyWith(defaultSubtitleLanguage: sub);
    await updateSettings(updated);
  }

  Future<void> updateResumeBehavior(String behavior) async {
    final updated = state.copyWith(resumeBehavior: behavior);
    await updateSettings(updated);
  }
}

/// Provider for global application settings.
final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  final repo = ref.watch(appSettingsRepositoryProvider);
  return AppSettingsNotifier(repo);
});

/// Convenience provider returning the active Accent Color.
final accentColorProvider = Provider<Color>((ref) {
  final accentValue = ref.watch(
    appSettingsProvider.select((s) => s.accentColorValue),
  );
  return Color(accentValue);
});
