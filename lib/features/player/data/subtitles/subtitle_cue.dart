/// Represents a single timed subtitle cue with start time, end time, and text lines.
class SubtitleCue {
  final Duration start;
  final Duration end;
  final List<String> lines;

  const SubtitleCue({
    required this.start,
    required this.end,
    required this.lines,
  });

  /// Checks if [position] falls within the cue's active display window,
  /// factoring in any user-configured [delaySeconds] offset.
  bool matches(Duration position, {double delaySeconds = 0.0}) {
    final effectiveMs = position.inMilliseconds;
    final shiftMs = (delaySeconds * 1000).round();
    final startMs = start.inMilliseconds + shiftMs;
    final endMs = end.inMilliseconds + shiftMs;
    return effectiveMs >= startMs && effectiveMs <= endMs;
  }

  @override
  String toString() => 'SubtitleCue($start --> $end: ${lines.join(" / ")})';
}
