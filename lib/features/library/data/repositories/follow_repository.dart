import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/followed_anime.dart';

/// Repository managing followed (bookmarked) anime persistence.
class FollowRepository {
  static const String _idsKey = 'followed_anime_ids';
  static const String _dataKey = 'followed_anime_data_v1';

  final SharedPreferences? _prefs;
  SharedPreferencesAsync? _asyncPrefs;

  FollowRepository([this._prefs]);

  SharedPreferencesAsync get _getAsyncPrefs {
    _asyncPrefs ??= SharedPreferencesAsync();
    return _asyncPrefs!;
  }

  final _idsController = StreamController<Set<int>>.broadcast();
  final _listController = StreamController<List<FollowedAnime>>.broadcast();

  Set<int>? _cachedIds;
  List<FollowedAnime>? _cachedList;

  Stream<Set<int>> get followStream => _idsController.stream;
  Stream<List<FollowedAnime>> get followedAnimeStream => _listController.stream;

  Future<void> _loadCache() async {
    if (_cachedIds != null && _cachedList != null) return;

    final list = <FollowedAnime>[];
    final idSet = <int>{};

    String? dataJsonStr;
    List<String> rawIds = [];

    if (_prefs != null) {
      try {
        dataJsonStr = _prefs.getString(_dataKey);
        rawIds = _prefs.getStringList(_idsKey) ?? [];
      } catch (_) {}
    }

    if (dataJsonStr == null || dataJsonStr.isEmpty) {
      try {
        dataJsonStr = await _getAsyncPrefs.getString(_dataKey);
        rawIds = await _getAsyncPrefs.getStringList(_idsKey) ?? [];
      } catch (_) {}
    }

      if (dataJsonStr != null && dataJsonStr.isNotEmpty) {
        try {
          final decoded = jsonDecode(dataJsonStr) as List<dynamic>;
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              final followed = FollowedAnime.fromJson(item);
              list.add(followed);
              idSet.add(followed.id);
            }
          }
        } catch (_) {
          // Backup corrupted data before it is lost or overwritten
          try {
            final backupKey = '${_dataKey}_corrupt_backup_${DateTime.now().millisecondsSinceEpoch}';
            _prefs?.setString(backupKey, dataJsonStr);
            _getAsyncPrefs.setString(backupKey, dataJsonStr);
          } catch (_) {}
        }
      }

      // Merge legacy IDs if any are not in the structured list
      for (final raw in rawIds) {
        final id = int.tryParse(raw) ?? 0;
        if (id > 0 && !idSet.contains(id)) {
          idSet.add(id);
          list.add(FollowedAnime(
            id: id,
            title: 'Anime #$id',
            followedAt: DateTime.now(),
          ));
        }
      }

    _cachedIds = idSet;
    _cachedList = list;
  }

  Future<Set<int>> getFollowedIds() async {
    await _loadCache();
    return Set.unmodifiable(_cachedIds!);
  }

  Future<List<FollowedAnime>> getFollowedList({FollowSort sort = FollowSort.recentlyFollowed}) async {
    await _loadCache();
    final items = List<FollowedAnime>.from(_cachedList!);
    _sortList(items, sort);
    return items;
  }

  Future<bool> isFollowing(int animeId) async {
    final ids = await getFollowedIds();
    return ids.contains(animeId);
  }

  Future<bool> toggleFollow(int animeId, {FollowedAnime? metadata}) async {
    await _loadCache();
    final isFollowed = _cachedIds!.contains(animeId);

    if (isFollowed) {
      await unfollow(animeId);
      return false;
    } else {
      final item = metadata ??
          FollowedAnime(
            id: animeId,
            title: 'Anime #$animeId',
            followedAt: DateTime.now(),
          );
      await follow(item);
      return true;
    }
  }

  Future<void> follow(FollowedAnime anime) async {
    await _loadCache();
    _cachedIds!.add(anime.id);
    _cachedList!.removeWhere((item) => item.id == anime.id);
    _cachedList!.insert(0, anime);

    await _persist();
    _notify();
  }

  Future<void> unfollow(int animeId) async {
    await _loadCache();
    _cachedIds!.remove(animeId);
    _cachedList!.removeWhere((item) => item.id == animeId);

    await _persist();
    _notify();
  }

  Future<void> replaceFollowedList(List<FollowedAnime> newList) async {
    _cachedList = List.from(newList);
    _cachedIds = newList.map((e) => e.id).toSet();
    await _persist();
    _notify();
  }

  void _sortList(List<FollowedAnime> list, FollowSort sort) {
    switch (sort) {
      case FollowSort.recentlyFollowed:
        list.sort((a, b) => b.followedAt.compareTo(a.followedAt));
        break;
      case FollowSort.title:
        list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case FollowSort.score:
        list.sort((a, b) => b.score.compareTo(a.score));
        break;
    }
  }

  Future<void> _persist() async {
    if (_cachedIds == null || _cachedList == null) return;

    final idStrings = _cachedIds!.map((e) => e.toString()).toList();
    final jsonStr = jsonEncode(_cachedList!.map((e) => e.toJson()).toList());

    try {
      await _getAsyncPrefs.setStringList(_idsKey, idStrings);
      await _getAsyncPrefs.setString(_dataKey, jsonStr);
    } catch (_) {}

    if (_prefs != null) {
      try {
        await _prefs.setStringList(_idsKey, idStrings);
        await _prefs.setString(_dataKey, jsonStr);
      } catch (_) {}
    }
  }

  void _notify() {
    if (_cachedIds != null) {
      _idsController.add(Set.unmodifiable(_cachedIds!));
    }
    if (_cachedList != null) {
      _listController.add(List.unmodifiable(_cachedList!));
    }
  }
}
