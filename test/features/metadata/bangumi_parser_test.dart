import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:anime_stream/features/metadata/data/datasources/bangumi_remote_data_source.dart';

void main() {
  group('Bangumi Remote Data Source Parsing Tests', () {
    test('Parses search subjects JSON fixture correctly', () async {
      final file = File('test/fixtures/bangumi_search_frieren.json');
      final jsonStr = await file.readAsString();
      final Map<String, dynamic> data = json.decode(jsonStr);

      final list = data['data'] as List<dynamic>;
      expect(list.isNotEmpty, isTrue);

      final summary = BangumiRemoteDataSource.parseAnimeSummary(list[0] as Map<String, dynamic>);
      expect(summary.id, equals(400602));
      expect(summary.titles.original, equals('葬送のフリーレン'));
      expect(summary.titles.localized, equals('葬送的芙莉莲'));
      expect(summary.titles.english, equals("Frieren: Beyond Journey's End"));
      expect(summary.score, equals(8.5));
      expect(summary.ratingCount, equals(36616));
      expect(summary.rank, equals(43));
      expect(summary.eps, equals(28));
      expect(summary.posterUrl, isNotNull);
      expect(summary.posterUrl, contains('400602'));
    });

    test('Parses subject detail JSON fixture correctly', () async {
      final file = File('test/fixtures/bangumi_subject_frieren.json');
      final jsonStr = await file.readAsString();
      final Map<String, dynamic> data = json.decode(jsonStr);

      final detail = BangumiRemoteDataSource.parseAnimeDetail(data);
      expect(detail.id, equals(400602));
      expect(detail.titles.original, equals('葬送のフリーレン'));
      expect(detail.titles.localized, equals('葬送的芙莉莲'));
      expect(detail.score, equals(8.5));
      expect(detail.eps, equals(28));
      expect(detail.tags.isNotEmpty, isTrue);

      // Verify top tag
      final topTag = detail.tags.first;
      expect(topTag.name, equals('治愈'));
      expect(topTag.count, equals(8131));
    });

    test('Parses episodes list JSON fixture correctly', () async {
      final file = File('test/fixtures/bangumi_episodes_frieren.json');
      final jsonStr = await file.readAsString();
      final Map<String, dynamic> data = json.decode(jsonStr);

      final list = (data['data'] as List<dynamic>)
          .map((e) => BangumiRemoteDataSource.parseEpisode(e as Map<String, dynamic>))
          .toList();

      expect(list.length, equals(28));

      // Verify Episode 1
      final ep1 = list[0];
      expect(ep1.number, equals(1.0));
      expect(ep1.sort, equals(1));
      expect(ep1.title, equals('冒险结束'));
      expect(ep1.titleOriginal, equals('冒険の終わり'));
      expect(ep1.airDate, equals('2023-09-29'));
      expect(ep1.duration, equals('00:26:00'));

      // Verify Episode 28
      final ep28 = list[27];
      expect(ep28.number, equals(28.0));
      expect(ep28.sort, equals(28));
      expect(ep28.title, equals('因为下次再见时会很难为情'));
    });
  });
}
