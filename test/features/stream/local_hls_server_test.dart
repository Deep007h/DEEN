import 'package:flutter_test/flutter_test.dart';
import 'package:anime_stream/features/stream/data/hls/hls_parser.dart';
import 'package:anime_stream/features/stream/data/hls/local_hls_server.dart';

void main() {
  group('HlsParser Duration & Validation Tests', () {
    test('calculateDuration sums #EXTINF durations correctly', () {
      const playlist = '''
#EXTM3U
#EXT-X-VERSION:3
#EXT-X-TARGETDURATION:10
#EXTINF:9.000,
seg1.ts
#EXTINF:10.500,
seg2.ts
#EXTINF:4.500,
seg3.ts
#EXT-X-ENDLIST
''';
      final dur = HlsParser.calculateDuration(playlist);
      expect(dur, 24.0);
    });

    test('calculateDuration returns null for Master playlist', () {
      const master = '''
#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=1280000,RESOLUTION=1280x720
/variant-720p.m3u8
''';
      final dur = HlsParser.calculateDuration(master);
      expect(dur, isNull);
    });
  });

  group('LocalHlsServer Tests', () {
    test('starts and binds to loopback interface with ephemeral port', () async {
      final server = LocalHlsServer.instance;
      await server.start();

      expect(server.isRunning, isTrue);
      expect(server.port, greaterThan(0));

      await server.stop();
    });

    test('rewrites EXT-X-MEDIA subtitles playlists to proxied local URLs', () {
      final server = LocalHlsServer.instance;
      const masterContent = '''
#EXTM3U
#EXT-X-VERSION:3
#EXT-X-MEDIA:TYPE=SUBTITLES,GROUP-ID="subs",NAME="English",DEFAULT=YES,AUTOSELECT=YES,FORCED=NO,LANGUAGE="en",URI="sub_eng.m3u8"
#EXT-X-STREAM-INF:BANDWIDTH=1280000,RESOLUTION=1280x720,SUBTITLES="subs"
variant-720p.m3u8
''';

      final rewritten = server.rewriteMasterPlaylistForTesting(
        masterContent,
        'https://cdn.example.com/hls/master.m3u8',
      );

      expect(rewritten, contains('URI="http://127.0.0.1:0/variant-test_token-0.m3u8"'));
      expect(rewritten, contains('http://127.0.0.1:0/variant-test_token-1.m3u8'));
    });

    test('rewrites EXT-X-MAP initialization chunks to proxied segment URLs', () {
      final server = LocalHlsServer.instance;
      const variantContent = '''
#EXTM3U
#EXT-X-VERSION:7
#EXT-X-TARGETDURATION:6
#EXT-X-MAP:URI="init.mp4"
#EXTINF:6.000,
seg1.mp4
#EXT-X-ENDLIST
''';

      final rewritten = server.rewriteVariantPlaylistForTesting(
        variantContent,
        'https://cdn.example.com/hls/variant-720p.m3u8',
      );

      expect(rewritten, contains('#EXT-X-MAP:URI="http://127.0.0.1:0/segment-test_token?url=https%3A%2F%2Fcdn.example.com%2Fhls%2Finit.mp4"'));
      expect(rewritten, contains('http://127.0.0.1:0/segment-test_token?url=https%3A%2F%2Fcdn.example.com%2Fhls%2Fseg1.mp4'));
    });
  });
}
