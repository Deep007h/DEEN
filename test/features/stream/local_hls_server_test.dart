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
  });
}
