import 'dart:convert';
import '../../../library/domain/models/followed_anime.dart';
import '../../../player/domain/models/watch_history_item.dart';

/// Data backup envelope containing user favorites and watch history.
class DataBackup {
  final int version;
  final DateTime exportedAt;
  final List<FollowedAnime> favorites;
  final List<WatchHistoryItem> history;

  const DataBackup({
    this.version = 1,
    required this.exportedAt,
    required this.favorites,
    required this.history,
  });

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'exportedAt': exportedAt.toIso8601String(),
      'favorites': favorites.map((e) => e.toJson()).toList(),
      'history': history.map((e) => e.toJson()).toList(),
    };
  }

  String toFormattedJson() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }

  factory DataBackup.fromJson(Map<String, dynamic> json) {
    final version = json['version'] as int? ?? 1;
    final exportedAt = json['exportedAt'] != null
        ? DateTime.tryParse(json['exportedAt'] as String) ?? DateTime.now()
        : DateTime.now();

    final favoritesRaw = json['favorites'] as List<dynamic>? ?? [];
    final favorites = favoritesRaw
        .whereType<Map>()
        .map((e) => FollowedAnime.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final historyRaw = json['history'] as List<dynamic>? ?? [];
    final history = historyRaw
        .whereType<Map>()
        .map((e) => WatchHistoryItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return DataBackup(
      version: version,
      exportedAt: exportedAt,
      favorites: favorites,
      history: history,
    );
  }

  static DataBackup? tryParse(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is Map) {
        return DataBackup.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {}
    return null;
  }
}
