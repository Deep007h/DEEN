import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:anime_stream/features/downloads/data/download_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    SharedPreferences.setMockInitialValues({});
  });

  group('DownloadService Tests', () {
    test('startDownload, tracks progress, and saves offline episode', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = DownloadService(prefs: prefs);

      expect(service.downloads, isEmpty);
      expect(service.isDownloaded(400602, 1), isFalse);

      final entry = await service.startDownload(
        animeId: 400602,
        episodeNumber: 1,
        title: 'Episode 1',
        animeTitle: "Frieren: Beyond Journey's End",
        streamUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      );

      expect(entry.id, '400602_1');
      expect(service.downloads, hasLength(1));

      // Await background download task
      await service.getActiveDownloadTask(entry.id);

      expect(service.isDownloaded(400602, 1), isTrue);
      expect(service.totalUsedBytes, greaterThan(0));

      // Re-load service with same prefs to test persistence
      final restoredService = DownloadService(prefs: prefs);
      expect(restoredService.downloads, hasLength(1));
      expect(restoredService.isDownloaded(400602, 1), isTrue);

      // Delete download
      await service.deleteDownload('400602_1');
      expect(service.downloads, isEmpty);
      expect(service.isDownloaded(400602, 1), isFalse);
    });
  });
}
