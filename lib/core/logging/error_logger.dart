import 'package:flutter/foundation.dart';

/// Centralized error logger and telemetry reporting hook.
/// Captures uncaught Flutter framework errors, platform asynchronous dispatcher errors,
/// and video playback failures. Ready for Sentry or Firebase Crashlytics plugin.
class ErrorLogger {
  static bool _initialized = false;

  /// Optional custom error sink for remote reporting (e.g., Sentry, Datadog).
  static void Function(Object error, StackTrace? stack, String? hint)? onReportError;

  /// Initializes framework-level error handlers.
  static void initialize() {
    if (_initialized) return;
    _initialized = true;

    // Capture Flutter framework widget build/layout errors
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      logError(
        details.exception,
        stackTrace: details.stack,
        context: details.context?.toString() ?? 'Flutter framework error',
      );
      originalOnError?.call(details);
    };

    // Capture platform dispatcher uncaught asynchronous errors
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      logError(
        error,
        stackTrace: stack,
        context: 'Uncaught platform asynchronous error',
      );
      return true; // Handled
    };

    if (kDebugMode) {
      debugPrint('[ErrorLogger] Telemetry and crash handlers initialized.');
    }
  }

  /// Logs and reports a captured error or exception.
  static void logError(
    Object error, {
    StackTrace? stackTrace,
    String? context,
  }) {
    // Print directly so adb logcat and Android logging always capture it
    debugPrint('════════════ [ErrorLogger] ERROR ════════════');
    if (context != null) debugPrint('Context: $context');
    debugPrint('Error: $error');
    if (stackTrace != null) debugPrint('Stack: $stackTrace');
    debugPrint('════════════════════════════════════════════');

    onReportError?.call(error, stackTrace, context);
  }

  /// Logs a warning message.
  static void logWarning(String message, {String? tag}) {
    final prefix = tag != null ? '[$tag] ' : '';
    debugPrint('[ErrorLogger:WARN] $prefix$message');
  }

  /// Logs an informational message.
  static void logInfo(String message, {String? tag}) {
    final prefix = tag != null ? '[$tag] ' : '';
    debugPrint('[ErrorLogger:INFO] $prefix$message');
  }
}
