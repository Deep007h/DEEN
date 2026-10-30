import 'package:flutter_test/flutter_test.dart';
import 'package:anime_stream/features/player/data/subtitles/subtitle_cue.dart';
import 'package:anime_stream/features/player/data/subtitles/subtitle_parser.dart';

void main() {
  group('SubtitleParser Tests', () {
    test('parses WebVTT content with HTML tag stripping', () {
      const vtt = '''WEBVTT

00:20.240 --> 00:29.210
<b>Beyond Journey's End</b>

01:29.980 --> 01:39.740
<b>At the northernmost end of the continent,
I arrived at the place that
the people of this world call heaven:
Aureole, the land where souls rest.</b>
''';

      final cues = SubtitleParser.parse(vtt);
      expect(cues, hasLength(2));

      expect(cues[0].start, const Duration(seconds: 20, milliseconds: 240));
      expect(cues[0].end, const Duration(seconds: 29, milliseconds: 210));
      expect(cues[0].lines, ["Beyond Journey's End"]);

      expect(cues[1].start, const Duration(minutes: 1, seconds: 29, milliseconds: 980));
      expect(cues[1].end, const Duration(minutes: 1, seconds: 39, milliseconds: 740));
      expect(cues[1].lines.length, 4);
      expect(cues[1].lines.first, "At the northernmost end of the continent,");
      expect(cues[1].lines.last, "Aureole, the land where souls rest.");
    });

    test('parses SRT content correctly', () {
      const srt = '''1
00:00:20,240 --> 00:00:29,210
Beyond Journey's End

2
00:01:29,980 --> 00:01:39,740
Second subtitle line
''';

      final cues = SubtitleParser.parse(srt);
      expect(cues, hasLength(2));
      expect(cues[0].start, const Duration(seconds: 20, milliseconds: 240));
      expect(cues[0].end, const Duration(seconds: 29, milliseconds: 210));
      expect(cues[0].lines, ["Beyond Journey's End"]);
    });

    test('parses ASS / SSA content with style stripping', () {
      const ass = '''[Script Info]
Title: Sample
[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:20.24,0:00:29.21,Default,,0,0,0,,{\\b1}Beyond Journey's End{\\b0}
Dialogue: 0,0:01:29.98,0:01:39.74,Default,,0,0,0,,Line 1\\NLine 2
''';

      final cues = SubtitleParser.parse(ass);
      expect(cues, hasLength(2));
      expect(cues[0].start, const Duration(seconds: 20, milliseconds: 240));
      expect(cues[0].end, const Duration(seconds: 29, milliseconds: 210));
      expect(cues[0].lines, ["Beyond Journey's End"]);
      expect(cues[1].lines, ["Line 1", "Line 2"]);
    });

    test('SubtitleCue matches position and respects delaySeconds', () {
      const cue = SubtitleCue(
        start: Duration(seconds: 10),
        end: Duration(seconds: 15),
        lines: ['Hello world'],
      );

      // Normal matching without delay
      expect(cue.matches(const Duration(seconds: 9)), isFalse);
      expect(cue.matches(const Duration(seconds: 10)), isTrue);
      expect(cue.matches(const Duration(seconds: 12)), isTrue);
      expect(cue.matches(const Duration(seconds: 15)), isTrue);
      expect(cue.matches(const Duration(seconds: 16)), isFalse);

      // Matching with +2.0s delay (window shifts to 12s -> 17s)
      expect(cue.matches(const Duration(seconds: 10), delaySeconds: 2.0), isFalse);
      expect(cue.matches(const Duration(seconds: 13), delaySeconds: 2.0), isTrue);
      expect(cue.matches(const Duration(seconds: 17), delaySeconds: 2.0), isTrue);
      expect(cue.matches(const Duration(seconds: 18), delaySeconds: 2.0), isFalse);

      // Matching with -2.0s delay (window shifts to 8s -> 13s)
      expect(cue.matches(const Duration(seconds: 7), delaySeconds: -2.0), isFalse);
      expect(cue.matches(const Duration(seconds: 8), delaySeconds: -2.0), isTrue);
      expect(cue.matches(const Duration(seconds: 13), delaySeconds: -2.0), isTrue);
      expect(cue.matches(const Duration(seconds: 14), delaySeconds: -2.0), isFalse);
    });
  });
}
