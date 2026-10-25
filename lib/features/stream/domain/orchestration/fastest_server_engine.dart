import 'dart:async';
import 'package:dio/dio.dart';
import '../models/stream_variant.dart';

/// Measurement result for a candidate stream variant / server.
class ServerLatencyResult {
  final StreamVariant variant;
  final int latencyMs;
  final bool isHealthy;
  final String serverName;

  const ServerLatencyResult({
    required this.variant,
    required this.latencyMs,
    required this.isHealthy,
    required this.serverName,
  });

  String get badgeText {
    if (!isHealthy) return 'Offline';
    if (latencyMs < 150) return '⚡ ${latencyMs}ms (Fastest)';
    if (latencyMs < 350) return '🟢 ${latencyMs}ms';
    return '🟡 ${latencyMs}ms';
  }
}

/// Automated detection engine that concurrent-probes candidate video streams/servers,
/// measures Round-Trip Time (RTT) / Time-To-First-Byte (TTFB), and selects the fastest
/// healthy stream with fallback failover.
class FastestServerEngine {
  final Dio _dio;
  final Duration probeTimeout;

  FastestServerEngine({
    Dio? client,
    this.probeTimeout = const Duration(milliseconds: 350),
  }) : _dio = client ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(milliseconds: 350),
                receiveTimeout: const Duration(milliseconds: 350),
              ),
            );

  /// Probes candidate variants in parallel and returns them sorted by fastest response time.
  Future<List<StreamVariant>> rankBySpeed(
    List<StreamVariant> variants, [
    List<ServerLatencyResult>? precomputedResults,
  ]) async {
    if (variants.isEmpty) return const [];
    if (variants.length == 1) return variants;

    final results = precomputedResults ?? await probeAll(variants);
    final sorted = List<ServerLatencyResult>.from(results)
      ..sort((a, b) {
        if (a.isHealthy && !b.isHealthy) return -1;
        if (!a.isHealthy && b.isHealthy) return 1;
        return a.latencyMs.compareTo(b.latencyMs);
      });

    return sorted.map((r) => r.variant).toList();
  }

  /// Probes all candidate variants concurrently and returns detailed latency results.
  Future<List<ServerLatencyResult>> probeAll(List<StreamVariant> variants) async {
    if (variants.isEmpty) return const [];

    final futures = List.generate(variants.length, (index) {
      return probeOne(variants[index], serverIndex: index + 1);
    });
    return Future.wait(futures);
  }

  /// Probes a single stream variant via lightweight byte-range GET / HEAD request.
  Future<ServerLatencyResult> probeOne(StreamVariant variant, {int serverIndex = 1}) async {
    final sw = Stopwatch()..start();
    final serverName = 'Server $serverIndex';

    try {
      final probeHeaders = Map<String, String>.from(variant.headers);
      probeHeaders['Range'] = 'bytes=0-1024';

      final response = await _dio.get(
        variant.url,
        options: Options(
          responseType: ResponseType.stream,
          headers: probeHeaders,
          sendTimeout: probeTimeout,
          receiveTimeout: probeTimeout,
          validateStatus: (status) => status != null && status < 400,
        ),
      );

      sw.stop();
      final status = response.statusCode ?? 0;
      final isHealthy = (status == 200 || status == 206 || status == 302);

      return ServerLatencyResult(
        variant: variant,
        latencyMs: sw.elapsedMilliseconds,
        isHealthy: isHealthy,
        serverName: serverName,
      );
    } catch (_) {
      sw.stop();
      return ServerLatencyResult(
        variant: variant,
        latencyMs: 99999,
        isHealthy: false,
        serverName: serverName,
      );
    }
  }
}
