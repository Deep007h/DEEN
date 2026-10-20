import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Diagnostic log entry recording resolution attempts, HTTP status, and errors.
class DiagnosticEntry {
  final DateTime timestamp;
  final String level; // INFO, WARN, ERROR
  final String message;
  final Map<String, dynamic> details;

  const DiagnosticEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.details = const {},
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'level': level,
        'message': message,
        'details': details,
      };

  factory DiagnosticEntry.fromJson(Map<String, dynamic> json) => DiagnosticEntry(
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
        level: json['level'] as String? ?? 'INFO',
        message: json['message'] as String? ?? '',
        details: (json['details'] as Map?)?.cast<String, dynamic>() ?? const {},
      );

  @override
  String toString() {
    final t = timestamp.toIso8601String().substring(11, 19);
    final d = details.isNotEmpty ? ' | details: $details' : '';
    return '[$t] [$level] $message$d';
  }
}

/// Stores and manages diagnostic resolution traces locally.
class DiagnosticsRepository {
  final SharedPreferences? _prefs;
  final List<DiagnosticEntry> _buffer = [];

  DiagnosticsRepository([this._prefs]);

  static const _kSavedReportKey = 'stream_last_problem_report';

  List<DiagnosticEntry> get currentSessionLogs => List.unmodifiable(_buffer);

  void info(String message, [Map<String, dynamic> details = const {}]) {
    _add('INFO', message, details);
  }

  void warn(String message, [Map<String, dynamic> details = const {}]) {
    _add('WARN', message, details);
  }

  void error(String message, [Map<String, dynamic> details = const {}]) {
    _add('ERROR', message, details);
  }

  void _add(String level, String message, Map<String, dynamic> details) {
    final entry = DiagnosticEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      details: details,
    );
    print('[STREAM_DIAG:$level] $message ${details.isNotEmpty ? details : ""}');
    _buffer.add(entry);
    if (_buffer.length > 200) {
      _buffer.removeAt(0);
    }
  }

  /// Clears in-memory session trace.
  void clear() => _buffer.clear();

  /// Saves the current diagnostic report locally to SharedPreferences.
  Future<void> saveProblemReport({
    required int animeId,
    required String animeTitle,
    required int episodeNumber,
    String? note,
  }) async {
    if (_prefs == null) return;

    final report = {
      'animeId': animeId,
      'animeTitle': animeTitle,
      'episodeNumber': episodeNumber,
      'reportedAt': DateTime.now().toIso8601String(),
      'note': note ?? '',
      'logs': _buffer.map((e) => e.toJson()).toList(),
    };

    await _prefs.setString(_kSavedReportKey, jsonEncode(report));
  }

  /// Formats the current buffer as a diagnostic text dump for copying.
  String generateDiagnosticReport({
    int? animeId,
    String? animeTitle,
    int? episodeNumber,
  }) {
    final sb = StringBuffer();
    sb.writeln('=== DEEN DIAGNOSTIC REPORT ===');
    sb.writeln('Generated: ${DateTime.now().toUtc().toIso8601String()}');
    if (animeTitle != null) sb.writeln('Anime: $animeTitle (ID: $animeId)');
    if (episodeNumber != null) sb.writeln('Episode: $episodeNumber');
    sb.writeln('--- Trace Logs (${_buffer.length} events) ---');
    for (final entry in _buffer) {
      sb.writeln(entry.toString());
    }
    sb.writeln('=== END OF REPORT ===');
    return sb.toString();
  }
}
