import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/watch_history_item.dart';

import '../../../settings/data/repositories/app_settings_repository.dart' show sharedPreferencesProvider;

/// Provider for [PlaybackHistoryRepository].
final playbackHistoryRepositoryProvider = Provider<PlaybackHistoryRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PlaybackHistoryRepository(prefs);
});

/// Repository managing playback history, episode progress, and resume positions.
class PlaybackHistoryRepository {
  static const String _recordsKey = 'watch_history_records_v1';
  final SharedPreferences? _prefs;
  SharedPreferencesAsync? _asyncPrefs;

  PlaybackHistoryRepository([this._prefs]);

  SharedPreferencesAsync get _getAsyncPrefs {
    _asyncPrefs ??= SharedPreferencesAsync();
    return _asyncPrefs!;
  }

  final _historyController = StreamController<List<WatchHistoryItem>>.broadcast();
  List<WatchHistoryItem>? _cachedHistory;

  Stream<List<WatchHistoryItem>> get watchHistoryStream => _historyController.stream;

  String _lastEpKey(int animeId) => 'last_ep_$animeId';
  String _progressKey(int animeId, int ep) => 'progress_${animeId}_$ep';
  String _positionKey(int animeId, int ep) => 'position_sec_${animeId}_$ep';

  Future<int?> getLastWatchedEpisode(int animeId) async {
    final key = _lastEpKey(animeId);
    if (_prefs != null) {
      final v = _prefs.getInt(key);
      if (v != null) return v;
    }
    try {
      final v = await _getAsyncPrefs.getInt(key);
      if (v != null) return v;
    } catch (_) {}
    return null;
  }

  Future<void> setLastWatchedEpisode(int animeId, int ep) async {
    final key = _lastEpKey(animeId);
    try {
      await _getAsyncPrefs.setInt(key, ep);
    } catch (_) {}
    if (_prefs != null) {
      try {
        await _prefs.setInt(key, ep);
      } catch (_) {}
    }
  }

  Future<double?> getEpisodeProgress(int animeId, int ep) async {
    final key = _progressKey(animeId, ep);
    if (_prefs != null) {
      final v = _prefs.getDouble(key);
      if (v != null) return v;
    }
    try {
      final v = await _getAsyncPrefs.getDouble(key);
      if (v != null) return v;
    } catch (_) {}
    return null;
  }

  Future<int?> getEpisodePositionSeconds(int animeId, int ep) async {
    final key = _positionKey(animeId, ep);
    if (_prefs != null) {
      final v = _prefs.getInt(key);
      if (v != null) return v;
    }
    try {
      final v = await _getAsyncPrefs.getInt(key);
      if (v != null) return v;
    } catch (_) {}
    return null;
  }

  Future<void> setEpisodeProgress(int animeId, int ep, double progress) async {
    final key = _progressKey(animeId, ep);
    try {
      await _getAsyncPrefs.setDouble(key, progress);
    } catch (_) {}
    if (_prefs != null) {
      try {
        await _prefs.setDouble(key, progress);
      } catch (_) {}
    }
    await setLastWatchedEpisode(animeId, ep);
  }

  Future<List<WatchHistoryItem>> getHistoryList() async {
    if (_cachedHistory != null) {
      return List.unmodifiable(_cachedHistory!);
    }

    String? rawJson;
    if (_prefs != null) {
      try {
        rawJson = _prefs.getString(_recordsKey);
      } catch (_) {}
    }
    if (rawJson == null || rawJson.isEmpty) {
      try {
        rawJson = await _getAsyncPrefs.getString(_recordsKey);
      } catch (_) {}
    }

    final list = <WatchHistoryItem>[];
    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawJson) as List<dynamic>;
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            list.add(WatchHistoryItem.fromJson(item));
          }
        }
      } catch (_) {}
    }

    // Sort newest first
    list.sort((a, b) => b.lastWatchedAt.compareTo(a.lastWatchedAt));
    _cachedHistory = list;
    return List.unmodifiable(_cachedHistory!);
  }

  /// Saves playback progress and position in seconds, updating history list.
  Future<void> savePlaybackProgress(
    int animeId,
    int ep, {
    required int positionSeconds,
    required int totalDurationSeconds,
    String? animeTitle,
    String? posterUrl,
  }) async {
    final posKey = _positionKey(animeId, ep);
    try {
      await _getAsyncPrefs.setInt(posKey, positionSeconds);
    } catch (_) {}
    if (_prefs != null) {
      try {
        await _prefs.setInt(posKey, positionSeconds);
      } catch (_) {}
    }

    final fraction = totalDurationSeconds > 0
        ? (positionSeconds / totalDurationSeconds).clamp(0.0, 1.0)
        : 0.0;

    await setEpisodeProgress(animeId, ep, fraction);

    // Update history collection
    await getHistoryList();
    final currentList = List<WatchHistoryItem>.from(_cachedHistory ?? []);

    // Existing entry index for this anime
    final existingIndex = currentList.indexWhere((item) => item.animeId == animeId);
    final fallbackTitle = existingIndex >= 0
        ? currentList[existingIndex].animeTitle
        : 'Anime #$animeId';
    final fallbackPoster = existingIndex >= 0
        ? currentList[existingIndex].posterUrl
        : null;

    final newItem = WatchHistoryItem(
      animeId: animeId,
      episodeNumber: ep,
      animeTitle: (animeTitle != null && animeTitle.isNotEmpty)
          ? animeTitle
          : fallbackTitle,
      posterUrl: posterUrl ?? fallbackPoster,
      positionSeconds: positionSeconds,
      totalDurationSeconds: totalDurationSeconds,
      lastWatchedAt: DateTime.now(),
    );

    if (existingIndex >= 0) {
      currentList.removeAt(existingIndex);
    }
    currentList.insert(0, newItem);

    _cachedHistory = currentList;
    await _persistHistory();
    _historyController.add(List.unmodifiable(_cachedHistory!));
  }

  /// Removes an anime from watch history (swipe-to-delete).
  Future<void> deleteHistoryItem(int animeId, [int? ep]) async {
    await getHistoryList();
    final currentList = List<WatchHistoryItem>.from(_cachedHistory ?? []);

    if (ep != null) {
      currentList.removeWhere((item) => item.animeId == animeId && item.episodeNumber == ep);
    } else {
      currentList.removeWhere((item) => item.animeId == animeId);
    }

    _cachedHistory = currentList;
    await _persistHistory();
    _historyController.add(List.unmodifiable(_cachedHistory!));
  }

  /// Clears the entire watch history.
  Future<void> clearAllHistory() async {
    _cachedHistory = [];
    try {
      await _getAsyncPrefs.remove(_recordsKey);
    } catch (_) {}
    if (_prefs != null) {
      try {
        await _prefs.remove(_recordsKey);
      } catch (_) {}
    }
    _historyController.add(const []);
  }

  /// Alias for [clearAllHistory].
  Future<void> clearHistory() => clearAllHistory();

  /// Alias for [deleteHistoryItem] targeting a specific episode.
  Future<void> deleteEpisode(int animeId, int ep) => deleteHistoryItem(animeId, ep);

  Future<void> replaceHistoryList(List<WatchHistoryItem> newList) async {
    _cachedHistory = List.from(newList);
    _cachedHistory!.sort((a, b) => b.lastWatchedAt.compareTo(a.lastWatchedAt));
    await _persistHistory();
    _historyController.add(List.unmodifiable(_cachedHistory!));
  }

  Future<void> _persistHistory() async {
    final history = _cachedHistory;
    if (history == null) return;
    final jsonStr = jsonEncode(history.map((e) => e.toJson()).toList());

    try {
      await _getAsyncPrefs.setString(_recordsKey, jsonStr);
    } catch (_) {}

    if (_prefs != null) {
      try {
        await _prefs.setString(_recordsKey, jsonStr);
      } catch (_) {}
    }
  }

  /// An episode is marked completed if watched past 90%.
  Future<bool> isEpisodeWatched(int animeId, int ep) async {
    final progress = await getEpisodeProgress(animeId, ep);
    return progress != null && progress >= 0.90;
  }
}
