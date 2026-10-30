import 'subtitle_cue.dart';

/// Robust multi-format subtitle parser supporting WebVTT, SubRip (SRT), and Advanced SubStation (ASS/SSA).
class SubtitleParser {
  static final _vttSrtTimeRegex = RegExp(
    r'(?:(\d{1,2}):)?(\d{1,2}):(\d{2})[.,](\d{3})\s*-->\s*(?:(\d{1,2}):)?(\d{1,2}):(\d{2})[.,](\d{3})',
  );

  static final _assTimeRegex = RegExp(
    r'(\d+):(\d{2}):(\d{2})[.,](\d{2,3})',
  );

  static final _htmlTagRegex = RegExp(r'<[^>]*>');
  static final _assTagRegex = RegExp(r'\{[^}]*\}');

  /// Parses raw subtitle file content into a sorted list of [SubtitleCue].
  static List<SubtitleCue> parse(String content) {
    if (content.trim().isEmpty) return const [];

    final normalized = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    // 1. Detect ASS/SSA format
    if (normalized.contains('[Events]') || normalized.contains('Dialogue:')) {
      return _parseAss(normalized);
    }

    // 2. Parse WebVTT or SRT
    return _parseVttOrSrt(normalized);
  }

  static List<SubtitleCue> _parseVttOrSrt(String content) {
    final cues = <SubtitleCue>[];
    final blocks = content.split(RegExp(r'\n\s*\n'));

    for (final block in blocks) {
      final lines = block
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      if (lines.isEmpty) continue;
      // Skip header lines like WEBVTT, NOTE, STYLE
      if (lines[0].startsWith('WEBVTT') ||
          lines[0].startsWith('NOTE') ||
          lines[0].startsWith('STYLE')) {
        continue;
      }

      int timeIndex = -1;
      Match? timeMatch;

      for (int i = 0; i < lines.length; i++) {
        final match = _vttSrtTimeRegex.firstMatch(lines[i]);
        if (match != null) {
          timeIndex = i;
          timeMatch = match;
          break;
        }
      }

      if (timeMatch == null || timeIndex == -1) continue;

      final start = _parseVttSrtDuration(
        timeMatch.group(1),
        timeMatch.group(2)!,
        timeMatch.group(3)!,
        timeMatch.group(4)!,
      );

      final end = _parseVttSrtDuration(
        timeMatch.group(5),
        timeMatch.group(6)!,
        timeMatch.group(7)!,
        timeMatch.group(8)!,
      );

      final rawTextLines = lines.sublist(timeIndex + 1);
      final cleanLines = rawTextLines
          .map((l) => l.replaceAll(_htmlTagRegex, '').trim())
          .where((l) => l.isNotEmpty)
          .toList();

      if (cleanLines.isNotEmpty && end > start) {
        cues.add(SubtitleCue(start: start, end: end, lines: cleanLines));
      }
    }

    cues.sort((a, b) => a.start.compareTo(b.start));
    return cues;
  }

  static Duration _parseVttSrtDuration(
    String? hoursStr,
    String minutesStr,
    String secondsStr,
    String millisStr,
  ) {
    final hours = hoursStr != null ? int.tryParse(hoursStr) ?? 0 : 0;
    final minutes = int.tryParse(minutesStr) ?? 0;
    final seconds = int.tryParse(secondsStr) ?? 0;
    final millis = int.tryParse(millisStr) ?? 0;

    return Duration(
      hours: hours,
      minutes: minutes,
      seconds: seconds,
      milliseconds: millis,
    );
  }

  static List<SubtitleCue> _parseAss(String content) {
    final cues = <SubtitleCue>[];
    final lines = content.split('\n');

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (!line.startsWith('Dialogue:')) continue;

      // Dialogue: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
      final parts = line.split(',');
      if (parts.length < 10) continue;

      final startStr = parts[1].trim();
      final endStr = parts[2].trim();
      final text = parts.sublist(9).join(',');

      final start = _parseAssDuration(startStr);
      final end = _parseAssDuration(endStr);
      if (start == null || end == null || end <= start) continue;

      final cleanText = text
          .replaceAll(_assTagRegex, '')
          .replaceAll(r'\N', '\n')
          .replaceAll(r'\n', '\n');

      final cleanLines = cleanText
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      if (cleanLines.isNotEmpty) {
        cues.add(SubtitleCue(start: start, end: end, lines: cleanLines));
      }
    }

    cues.sort((a, b) => a.start.compareTo(b.start));
    return cues;
  }

  static Duration? _parseAssDuration(String s) {
    final match = _assTimeRegex.firstMatch(s);
    if (match == null) return null;

    final hours = int.tryParse(match.group(1)!) ?? 0;
    final minutes = int.tryParse(match.group(2)!) ?? 0;
    final seconds = int.tryParse(match.group(3)!) ?? 0;
    final fracStr = match.group(4)!;
    final millis = fracStr.length == 2
        ? (int.tryParse(fracStr) ?? 0) * 10
        : (int.tryParse(fracStr) ?? 0);

    return Duration(
      hours: hours,
      minutes: minutes,
      seconds: seconds,
      milliseconds: millis,
    );
  }
}
