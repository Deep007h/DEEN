import 'package:flutter_test/flutter_test.dart';
import 'package:anime_stream/features/stream/data/hls/hls_parser.dart';

void main() {
  group('HlsParser Tests', () {
    const sampleMasterPlaylist = '''
#EXTM3U
#EXT-X-VERSION:3
#EXT-X-STREAM-INF:BANDWIDTH=800000,RESOLUTION=640x360
360p.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=2500000,RESOLUTION=1280x720
720p.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=5000000,RESOLUTION=1920x1080
1080p.m3u8
''';

    test('Parses variants into sorted QualityOptions with Auto prepended', () {
      final qualities = HlsParser.parse(
        sampleMasterPlaylist,
        baseUrl: 'https://cdn.example.com/anime/master.m3u8',
      );

      expect(qualities.length, 4); // Auto + 1080p + 720p + 360p
      expect(qualities[0].isAuto, isTrue);
      expect(qualities[0].height, 1080);

      expect(qualities[1].label, '1080p');
      expect(qualities[1].height, 1080);
      expect(qualities[1].bandwidth, 5000000);
      expect(qualities[1].url, 'https://cdn.example.com/anime/1080p.m3u8');

      expect(qualities[2].label, '720p');
      expect(qualities[2].height, 720);

      expect(qualities[3].label, '360p');
      expect(qualities[3].height, 360);
    });

    test('Returns default Auto and fallback qualities for non-master content', () {
      final qualities = HlsParser.parse('Not a master playlist');
      expect(qualities.length, 1);
      expect(qualities[0].isAuto, isTrue);
    });
  });
}
