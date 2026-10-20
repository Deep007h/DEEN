import 'package:dio/dio.dart';
import '../../domain/models/quality_option.dart';

/// Parser for HLS (.m3u8) master playlists.
class HlsParser {
  const HlsParser();

  /// Calculates total playlist duration in seconds from #EXTINF tags.
  /// If [content] is a master playlist, returns null.
  static double? calculateDuration(String content) {
    if (content.contains('#EXT-X-STREAM-INF')) {
      return null;
    }
    double total = 0.0;
    final matches = RegExp(r'#EXTINF:\s*([0-9]+(?:\.[0-9]+)?)').allMatches(content);
    for (final m in matches) {
      final sec = double.tryParse(m.group(1)!);
      if (sec != null) total += sec;
    }
    return total;
  }

  /// Parses an HLS master playlist string and returns a list of [QualityOption]s.
  /// Prepends [QualityOption.auto()] as the first choice.
  static List<QualityOption> parse(String content, {String? baseUrl}) {
    final lines = content.split(RegExp(r'\r?\n'));
    final options = <QualityOption>[];

    int? pendingBandwidth;
    int? pendingWidth;
    int? pendingHeight;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      if (line.startsWith('#EXT-X-STREAM-INF:')) {
        // Parse attributes: BANDWIDTH=..., RESOLUTION=WxH
        final attrs = line.substring('#EXT-X-STREAM-INF:'.length);
        pendingBandwidth = _extractIntAttr(attrs, 'BANDWIDTH');

        final resMatch = RegExp(r'RESOLUTION=(\d+)x(\d+)', caseSensitive: false).firstMatch(attrs);
        if (resMatch != null) {
          pendingWidth = int.tryParse(resMatch.group(1)!);
          pendingHeight = int.tryParse(resMatch.group(2)!);
        }
      } else if (!line.startsWith('#') && (pendingBandwidth != null || pendingHeight != null)) {
        // This is the URI line following #EXT-X-STREAM-INF
        String variantUrl = line;
        if (baseUrl != null) {
          try {
            variantUrl = Uri.parse(baseUrl).resolve(line).toString();
          } catch (_) {
            variantUrl = line;
          }
        }

        final height = pendingHeight;
        final width = pendingWidth;
        final bandwidth = pendingBandwidth;

        final label = height != null
            ? '${height}p'
            : (bandwidth != null ? '${(bandwidth / 1000).round()}k' : 'Default');

        options.add(
          QualityOption(
            label: label,
            height: height,
            width: width,
            bandwidth: bandwidth,
            url: variantUrl,
            isAuto: false,
          ),
        );

        pendingBandwidth = null;
        pendingWidth = null;
        pendingHeight = null;
      }
    }

    // Sort descending by height, then by bandwidth
    options.sort((a, b) {
      final hA = a.height ?? 0;
      final hB = b.height ?? 0;
      if (hA != hB) return hB.compareTo(hA);
      return (b.bandwidth ?? 0).compareTo(a.bandwidth ?? 0);
    });

    // Remove duplicate labels
    final seen = <String>{};
    final uniqueOptions = options.where((o) => seen.add(o.label)).toList();

    final highest = uniqueOptions.isNotEmpty ? uniqueOptions.first.height : null;

    return [
      QualityOption.auto(currentHeight: highest),
      ...uniqueOptions,
    ];
  }

  /// Fetches an HLS playlist via HTTP, checks if it is a master playlist,
  /// and returns parsed quality options.
  static Future<List<QualityOption>> fetchAndParse(String url, Dio dio) async {
    try {
      final response = await dio.get<String>(
        url,
        options: Options(responseType: ResponseType.plain),
      );
      final body = response.data ?? '';
      if (body.contains('#EXT-X-STREAM-INF')) {
        return parse(body, baseUrl: url);
      }
    } catch (_) {
      // Fallback on network or format error
    }

    // Default fallback if not a multi-variant master playlist
    return [
      QualityOption.auto(currentHeight: 1080),
      QualityOption(label: '1080p', height: 1080, url: url),
      QualityOption(label: '720p', height: 720, url: url),
      QualityOption(label: '480p', height: 480, url: url),
      QualityOption(label: '360p', height: 360, url: url),
    ];
  }

  static int? _extractIntAttr(String attrs, String key) {
    final match = RegExp('$key=(\\d+)', caseSensitive: false).firstMatch(attrs);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
  }
}
