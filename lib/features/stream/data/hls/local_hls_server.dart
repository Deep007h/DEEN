import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Session metadata for a proxied HLS stream.
class _HlsSession {
  final String token;
  final String sourceUrl;
  final Map<String, String> headers;
  final DateTime createdAt;
  final Map<int, String> variantUrls = {};
  final Map<String, List<int>> _segmentCache = {};
  final List<String> segmentSequence = [];

  _HlsSession({
    required this.token,
    required this.sourceUrl,
    required this.headers,
  }) : createdAt = DateTime.now();
}

/// Lightweight, in-app HLS proxy server running on `127.0.0.1`.
///
/// Solves 3 critical architectural issues:
/// 1. **MIME-Type & Format Guarantees**: Forces FFmpeg/libmpv to recognize streams
///    as HLS 100% of the time by serving standard `.m3u8` URLs with
///    `application/vnd.apple.mpegurl` headers.
/// 2. **Header Enforcement**: Upstream CDNs (like `cdnx.aniwatchtv.site` and `megavid.buzz`)
///    require specific `Referer`, `Origin`, and `User-Agent` headers. Native media engines
///    often drop these headers on sub-playlist and segment requests. This proxy guarantees
///    every single request carries required headers.
/// 3. **Segment Pre-fetching**: Prefetches upcoming segments in memory for instant,
///    stutter-free playback and fast startup.
class LocalHlsServer {
  LocalHlsServer._();
  static final LocalHlsServer instance = LocalHlsServer._();

  HttpServer? _server;
  HttpClient? _httpClient;
  final Map<String, _HlsSession> _sessions = {};
  final Map<String, Future<List<int>?>> _inFlightRequests = {};
  int _tokenCounter = 0;
  bool _isStarting = false;

  /// Default headers to attach to upstream requests if not specified.
  static const Map<String, String> defaultUpstreamHeaders = {
    'Referer': 'https://megavid.buzz/',
    'Origin': 'https://megavid.buzz',
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Mobile Safari/537.36',
    'Accept': '*/*',
  };

  /// Whether the server is currently running.
  bool get isRunning => _server != null;

  /// The local port the server is listening on.
  int get port => _server?.port ?? 0;

  /// Starts the local HTTP server on loopback interface with an OS-assigned ephemeral port.
  Future<void> start() async {
    if (_server != null) return;
    if (_isStarting) {
      while (_isStarting) {
        await Future.delayed(const Duration(milliseconds: 20));
      }
      return;
    }

    _isStarting = true;
    try {
      _httpClient = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10)
        ..idleTimeout = const Duration(seconds: 20)
        ..maxConnectionsPerHost = 64
        ..badCertificateCallback = ((cert, host, port) => true);

      _server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        0, // Ephemeral port
        shared: false,
      );
      _server!.idleTimeout = null;

      _server!.listen(
        _handleRequest,
        onError: (err) {
          // Log or ignore socket errors
        },
      );
    } catch (_) {
      // Handle bind failure
    } finally {
      _isStarting = false;
    }
  }

  /// Registers a target stream URL and returns a local `http://127.0.0.1:$port/stream-$token.m3u8` URL.
  Future<String> proxyStream(
    String targetUrl, {
    Map<String, String>? headers,
  }) async {
    // In widget/integration test environments, bypass local proxy to prevent fake_async timer leaks
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return targetUrl;
    }

    await start();

    if (_server == null) {
      // Fallback if local server failed to bind
      return targetUrl;
    }

    _cleanOldSessions();

    final cleanUrl = targetUrl.split('#').first.trim();
    final token = '${DateTime.now().millisecondsSinceEpoch}_${++_tokenCounter}';
    final mergedHeaders = Map<String, String>.from(defaultUpstreamHeaders);
    if (headers != null) {
      mergedHeaders.addAll(headers);
    }

    _sessions[token] = _HlsSession(
      token: token,
      sourceUrl: cleanUrl,
      headers: mergedHeaders,
    );

    return 'http://127.0.0.1:$port/stream-$token.m3u8';
  }

  void _cleanOldSessions() {
    final now = DateTime.now();
    _sessions.removeWhere(
      (_, session) => now.difference(session.createdAt).inMinutes >= 30,
    );
  }

  /// Clears previous proxy sessions and active in-flight segment requests.
  void clearSessions() {
    _sessions.clear();
    _inFlightRequests.clear();
  }

  /// Alias for [clearSessions].
  void clearPreviousSessions() => clearSessions();

  Future<void> _handleRequest(HttpRequest request) async {
    final path = request.uri.path;

    // Enable CORS for all requests
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, HEAD, OPTIONS');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      return;
    }

    try {
      // 1. Master / Primary Stream: /stream-{token}.m3u8
      if (path.startsWith('/stream-') && path.endsWith('.m3u8')) {
        final token = path.substring('/stream-'.length, path.length - '.m3u8'.length);
        final session = _sessions[token];
        if (session == null) {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
          return;
        }

        await _serveMasterOrVariant(request, session, session.sourceUrl);
        return;
      }

      // 2. Variant Playlist: /variant-{token}-{index}.m3u8
      if (path.startsWith('/variant-') && path.endsWith('.m3u8')) {
        final content = path.substring('/variant-'.length, path.length - '.m3u8'.length);
        final parts = content.split('-');
        if (parts.length >= 2) {
          final token = parts.sublist(0, parts.length - 1).join('-');
          final index = int.tryParse(parts.last) ?? 0;
          final session = _sessions[token];
          final variantUrl = session?.variantUrls[index];

          if (session != null && variantUrl != null) {
            await _serveVariant(request, session, variantUrl);
            return;
          }
        }
      }

      // 3. Segment TS: /segment-{token}
      if (path.startsWith('/segment-')) {
        final token = path.substring('/segment-'.length);
        final session = _sessions[token];
        final rawTargetUrl = request.uri.queryParameters['url'];

        if (session != null && rawTargetUrl != null && rawTargetUrl.isNotEmpty) {
          await _serveSegment(request, session, rawTargetUrl);
          return;
        }
      }

      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
    } catch (e) {
      try {
        request.response.statusCode = HttpStatus.badGateway;
        await request.response.close();
      } catch (_) {}
    }
  }

  Future<void> _serveMasterOrVariant(
    HttpRequest request,
    _HlsSession session,
    String targetUrl,
  ) async {
    final upstreamData = await _fetchUpstreamString(targetUrl, session.headers);
    if (upstreamData == null || upstreamData.isEmpty) {
      request.response.statusCode = HttpStatus.badGateway;
      await request.response.close();
      return;
    }

    final isMaster = upstreamData.contains('#EXT-X-STREAM-INF');

    if (isMaster) {
      // Rewrite master playlist lines
      final rewritten = _rewriteMasterPlaylist(upstreamData, session, targetUrl);
      request.response.statusCode = HttpStatus.ok;
      request.response.headers.contentType =
          ContentType('application', 'vnd.apple.mpegurl', charset: 'utf-8');
      request.response.write(rewritten);
      await request.response.close();
    } else {
      // Directly a media variant playlist
      final rewritten = _rewriteVariantPlaylist(upstreamData, session, targetUrl);
      request.response.statusCode = HttpStatus.ok;
      request.response.headers.contentType =
          ContentType('application', 'vnd.apple.mpegurl', charset: 'utf-8');
      request.response.write(rewritten);
      await request.response.close();
    }
  }

  Future<void> _serveVariant(
    HttpRequest request,
    _HlsSession session,
    String variantUrl,
  ) async {
    final upstreamData = await _fetchUpstreamString(variantUrl, session.headers);
    if (upstreamData == null || upstreamData.isEmpty) {
      request.response.statusCode = HttpStatus.badGateway;
      await request.response.close();
      return;
    }

    final rewritten = _rewriteVariantPlaylist(upstreamData, session, variantUrl);
    request.response.statusCode = HttpStatus.ok;
    request.response.headers.contentType =
        ContentType('application', 'vnd.apple.mpegurl', charset: 'utf-8');
    request.response.write(rewritten);
    await request.response.close();
  }

  void _cacheSegment(_HlsSession session, String url, List<int> bytes) {
    if (!session._segmentCache.containsKey(url) && session._segmentCache.length >= 4) {
      session._segmentCache.remove(session._segmentCache.keys.first);
    }
    session._segmentCache[url] = bytes;
  }

  ContentType _getContentType(String url) {
    final uri = Uri.tryParse(url);
    final path = (uri != null ? uri.path : url.split('?').first).toLowerCase();
    if (path.endsWith('.m4s') || path.endsWith('.mp4')) {
      return ContentType('video', 'mp4');
    }
    if (path.endsWith('.aac')) {
      return ContentType('audio', 'aac');
    }
    if (path.endsWith('.vtt')) {
      return ContentType('text', 'vtt');
    }
    return ContentType('video', 'mp2t');
  }

  Future<void> _serveSegment(
    HttpRequest request,
    _HlsSession session,
    String segmentUrl,
  ) async {
    // 1. Check memory cache first
    final cached = session._segmentCache[segmentUrl];
    if (cached != null && cached.isNotEmpty) {
      request.response.statusCode = HttpStatus.ok;
      request.response.headers.contentType = _getContentType(segmentUrl);
      request.response.headers.contentLength = cached.length;
      request.response.add(cached);
      await request.response.close();
      _triggerPrefetch(session, segmentUrl);
      return;
    }

    // 2. Check in-flight requests deduplication
    final inFlight = _inFlightRequests[segmentUrl];
    if (inFlight != null) {
      final inFlightBytes = await inFlight;
      if (inFlightBytes != null && inFlightBytes.isNotEmpty) {
        request.response.statusCode = HttpStatus.ok;
        request.response.headers.contentType = _getContentType(segmentUrl);
        request.response.headers.contentLength = inFlightBytes.length;
        request.response.add(inFlightBytes);
        await request.response.close();
        _triggerPrefetch(session, segmentUrl);
        return;
      }
    }

    // 3. Fetch from upstream CDN and stream directly to client response while accumulating for cache
    final completer = Completer<List<int>?>();
    _inFlightRequests[segmentUrl] = completer.future;

    bool streamedAnyBytes = false;
    List<int>? finalBytes;

    try {
      final cleanUrl = segmentUrl.split('#').first.trim();
      final uri = Uri.parse(cleanUrl);
      final client = _httpClient ?? (HttpClient()..badCertificateCallback = ((_, __, ___) => true));

      for (int attempt = 0; attempt < 3; attempt++) {
        HttpClientResponse? upstreamResp;
        try {
          final req = await client.getUrl(uri).timeout(const Duration(seconds: 8));
          session.headers.forEach((k, v) {
            req.headers.set(k, v);
          });

          upstreamResp = await req.close().timeout(const Duration(seconds: 8));
          if (upstreamResp.statusCode == HttpStatus.ok) {
            request.response.statusCode = HttpStatus.ok;
            request.response.headers.contentType = _getContentType(segmentUrl);
            if (upstreamResp.contentLength > 0) {
              request.response.headers.contentLength = upstreamResp.contentLength;
            }

            final builder = BytesBuilder(copy: false);
            await for (final chunk in upstreamResp.timeout(const Duration(seconds: 8))) {
              request.response.add(chunk); // Stream to client immediately
              builder.add(chunk);           // Also cache
              streamedAnyBytes = true;
            }
            await request.response.close();
            finalBytes = builder.takeBytes();
            if (finalBytes.isNotEmpty) {
              _cacheSegment(session, segmentUrl, finalBytes);
            }
            break;
          } else {
            await upstreamResp.drain().timeout(const Duration(seconds: 2)).catchError((_) {});
          }
        } catch (e) {
          if (upstreamResp != null) {
            try {
              await upstreamResp.drain().timeout(const Duration(seconds: 1)).catchError((_) {});
            } catch (_) {}
          }
          if (streamedAnyBytes) {
            try {
              await request.response.close();
            } catch (_) {}
            break;
          }
        }

        if (attempt < 2 && !streamedAnyBytes) {
          await Future.delayed(Duration(milliseconds: 200 * (attempt + 1)));
        }
      }
    } finally {
      completer.complete(finalBytes);
      _inFlightRequests.remove(segmentUrl);
    }

    if (finalBytes != null && finalBytes.isNotEmpty) {
      _triggerPrefetch(session, segmentUrl);
      return;
    }

    if (streamedAnyBytes) {
      return;
    }

    // Upstream permanently failed for this segment (e.g. 403 / 500 / dropped CDN node):
    // Do NOT return 403 / 500 to MPV, as that causes libavformat to abort the entire stream.
    // Instead, serve a valid MPEG-TS null padding packet with HTTP 200 so playback seamlessly continues.
    print('[HLS_PROXY] Segment failed after 3 attempts: $segmentUrl. Serving graceful null TS frame.');
    request.response.statusCode = HttpStatus.ok;
    request.response.headers.contentType = _getContentType(segmentUrl);
    final nullPacket = Uint8List(188);
    nullPacket[0] = 0x47;
    nullPacket[1] = 0x1F;
    nullPacket[2] = 0xFF;
    nullPacket[3] = 0x10;
    nullPacket.fillRange(4, 188, 0xFF);
    request.response.headers.contentLength = 188;
    request.response.add(nullPacket);
    await request.response.close();
  }

  void _triggerPrefetch(_HlsSession session, String segmentUrl) {
    final idx = session.segmentSequence.indexOf(segmentUrl);
    if (idx != -1 && idx + 1 < session.segmentSequence.length) {
      final upcoming = session.segmentSequence.skip(idx + 1).take(2).toList();
      _prefetchSegments(session, upcoming);
    }
  }

  String _rewriteMasterPlaylist(
    String content,
    _HlsSession session,
    String baseUrl,
  ) {
    final lines = content.split(RegExp(r'\r?\n'));
    final output = <String>[];
    int variantIndex = 0;
    bool nextIsUri = false;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.startsWith('#EXT-X-STREAM-INF:')) {
        nextIsUri = true;
        output.add(line);
      } else if (nextIsUri && !trimmed.startsWith('#')) {
        nextIsUri = false;
        final resolvedUrl = _resolveUrl(baseUrl, trimmed);
        session.variantUrls[variantIndex] = resolvedUrl;

        output.add(
          'http://127.0.0.1:$port/variant-${session.token}-$variantIndex.m3u8',
        );
        variantIndex++;
      } else {
        output.add(line);
      }
    }

    return output.join('\n');
  }

  String _rewriteVariantPlaylist(
    String content,
    _HlsSession session,
    String baseUrl,
  ) {
    final lines = content.split(RegExp(r'\r?\n'));
    final output = <String>[];
    final segmentUrlsToPrefetch = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if (!trimmed.startsWith('#')) {
        // Segment URL
        final resolvedUrl = _resolveUrl(baseUrl, trimmed);
        final encoded = Uri.encodeComponent(resolvedUrl);

        if (!session.segmentSequence.contains(resolvedUrl)) {
          session.segmentSequence.add(resolvedUrl);
        }

        if (segmentUrlsToPrefetch.length < 3) {
          segmentUrlsToPrefetch.add(resolvedUrl);
        }

        output.add(
          'http://127.0.0.1:$port/segment-${session.token}?url=$encoded',
        );
      } else {
        output.add(line);
      }
    }

    // Prefetch first 2 segments asynchronously in background to ensure zero start delay
    if (segmentUrlsToPrefetch.isNotEmpty) {
      _prefetchSegments(session, segmentUrlsToPrefetch.take(2).toList());
    }

    return output.join('\n');
  }

  void _prefetchSegments(_HlsSession session, List<String> urls) {
    for (final url in urls) {
      if (session._segmentCache.containsKey(url)) continue;
      Future<List<int>?> future;
      final inFlight = _inFlightRequests[url];
      if (inFlight != null) {
        future = inFlight;
      } else {
        future = _fetchUpstreamBytes(url, session.headers);
        _inFlightRequests[url] = future;
      }
      future.then((bytes) {
        if (bytes != null && bytes.isNotEmpty) {
          _cacheSegment(session, url, bytes);
        }
      }).catchError((_) {}).whenComplete(() {
        if (_inFlightRequests[url] == future) {
          _inFlightRequests.remove(url);
        }
      });
    }
  }

  String _resolveUrl(String baseUrl, String relativeOrAbsolute) {
    if (relativeOrAbsolute.startsWith('http://') ||
        relativeOrAbsolute.startsWith('https://')) {
      return relativeOrAbsolute;
    }
    try {
      final base = Uri.parse(baseUrl);
      return base.resolve(relativeOrAbsolute).toString();
    } catch (_) {
      return relativeOrAbsolute;
    }
  }

  Future<String?> _fetchUpstreamString(
    String url,
    Map<String, String> headers,
  ) async {
    final cleanUrl = url.split('#').first.trim();
    for (int attempt = 0; attempt < 3; attempt++) {
      HttpClientResponse? resp;
      try {
        final uri = Uri.parse(cleanUrl);
        final client = _httpClient ?? (HttpClient()..badCertificateCallback = ((_, __, ___) => true));
        final req = await client.getUrl(uri).timeout(const Duration(seconds: 8));

        headers.forEach((k, v) {
          req.headers.set(k, v);
        });

        resp = await req.close().timeout(const Duration(seconds: 8));
        if (resp.statusCode == HttpStatus.ok) {
          return await resp.transform(utf8.decoder).join().timeout(const Duration(seconds: 8));
        } else {
          await resp.drain().timeout(const Duration(seconds: 2)).catchError((_) {});
        }
        if (attempt < 2) {
          await Future.delayed(Duration(milliseconds: 200 * (attempt + 1)));
        }
      } catch (_) {
        if (resp != null) {
          try {
            await resp.drain().timeout(const Duration(seconds: 1)).catchError((_) {});
          } catch (_) {}
        }
        if (attempt < 2) {
          await Future.delayed(Duration(milliseconds: 200 * (attempt + 1)));
        }
      }
    }
    return null;
  }

  Future<List<int>?> _fetchUpstreamBytes(
    String url,
    Map<String, String> headers,
  ) async {
    final cleanUrl = url.split('#').first.trim();
    HttpClientResponse? resp;
    try {
      final uri = Uri.parse(cleanUrl);
      final client = _httpClient ?? (HttpClient()..badCertificateCallback = ((_, __, ___) => true));
      final req = await client.getUrl(uri).timeout(const Duration(seconds: 8));

      headers.forEach((k, v) {
        req.headers.set(k, v);
      });

      resp = await req.close().timeout(const Duration(seconds: 8));
      if (resp.statusCode == HttpStatus.ok) {
        final builder = BytesBuilder(copy: false);
        await for (final chunk in resp.timeout(const Duration(seconds: 8))) {
          builder.add(chunk);
        }
        return builder.takeBytes();
      } else {
        await resp.drain().timeout(const Duration(seconds: 2)).catchError((_) {});
      }
    } catch (_) {
      if (resp != null) {
        try {
          await resp.drain().timeout(const Duration(seconds: 1)).catchError((_) {});
        } catch (_) {}
      }
    }
    return null;
  }

  /// Shuts down the server and cleans up active sessions.
  Future<void> stop() async {
    _sessions.clear();
    _inFlightRequests.clear();
    _httpClient?.close(force: true);
    _httpClient = null;
    await _server?.close(force: true);
    _server = null;
  }
}
