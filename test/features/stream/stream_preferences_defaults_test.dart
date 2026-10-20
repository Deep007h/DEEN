import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anime_stream/features/settings/data/repositories/app_settings_repository.dart';
import 'package:anime_stream/features/stream/data/repositories/stream_preferences_repository.dart';

void main() {
  group('Stream Preferences & AppSettings Integration Tests', () {
    test('StreamPreferencesRepository reads English and 1080p fallback from app_settings_v1', () async {
      SharedPreferences.setMockInitialValues({
        'app_settings_v1': jsonEncode({
          'defaultAudioLanguage': 'English',
          'defaultQuality': '1080p',
          'defaultSubtitleLanguage': 'Spanish',
        }),
      });

      final prefs = await SharedPreferences.getInstance();
      final repo = StreamPreferencesRepository(prefs);

      expect(repo.getGlobalAudioLanguage(), 'en');
      expect(repo.getGlobalQuality(), '1080p');
      expect(repo.getGlobalSubtitleLanguage(), 'es');
      expect(repo.getEffectiveAudioLanguage(12345), 'en');
      expect(repo.getEffectiveQuality(12345), '1080p');
    });

    test('AppSettingsNotifier synchronously updates stream preferences in SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final appRepo = AppSettingsRepository(prefs);
      final notifier = AppSettingsNotifier(appRepo);

      // Initially default
      final streamRepo = StreamPreferencesRepository(prefs);
      expect(streamRepo.getGlobalAudioLanguage(), 'ja');
      expect(streamRepo.getGlobalQuality(), 'Auto');

      // Update to English and 1080p
      await notifier.updateDefaultAudio('English');
      await notifier.updateDefaultQuality('1080p');

      expect(streamRepo.getGlobalAudioLanguage(), 'en');
      expect(streamRepo.getGlobalQuality(), '1080p');
      expect(prefs.getString('stream_pref_global_audio'), 'en');
      expect(prefs.getString('stream_pref_global_quality'), '1080p');
    });
  });
}
