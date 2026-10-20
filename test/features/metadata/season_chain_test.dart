import 'package:flutter_test/flutter_test.dart';
import 'package:anime_stream/features/metadata/data/datasources/bangumi_remote_data_source.dart';

void main() {
  group('Season Chain Construction Tests', () {
    test('Builds ordered season chain with prequel, current, and sequel', () {
      final relations = [
        {
          'id': 101,
          'name': 'Jujutsu Kaisen Prequel',
          'name_cn': '咒术回战 前传',
          'relation': '前传',
          'type': 2,
        },
        {
          'id': 103,
          'name': 'Jujutsu Kaisen Season 2',
          'name_cn': '咒术回战 第二季',
          'relation': '续集',
          'type': 2,
        },
        {
          'id': 104,
          'name': 'Jujutsu Kaisen 0 Movie',
          'name_cn': '剧场版 咒术回战 0',
          'relation': '剧场版',
          'type': 2,
        },
      ];

      final chain = BangumiRemoteDataSource.buildSeasonChain(102, relations);

      // Expected order:
      // 1. Season 1 (Prequel, id: 101)
      // 2. Season 2 (Current, id: 102)
      // 3. Season 3 (Sequel, id: 103)
      // 4. Movie: 剧场版 咒术回战 0 (id: 104)

      expect(chain.length, equals(4));

      expect(chain[0].id, equals(101));
      expect(chain[0].name, equals('Season 1 (Prequel)'));
      expect(chain[0].isCurrent, isFalse);

      expect(chain[1].id, equals(102));
      expect(chain[1].name, equals('Season 2'));
      expect(chain[1].isCurrent, isTrue);

      expect(chain[2].id, equals(103));
      expect(chain[2].name, equals('Season 3'));
      expect(chain[2].isCurrent, isFalse);

      expect(chain[3].id, equals(104));
      expect(chain[3].name, contains('Movie'));
      expect(chain[3].isCurrent, isFalse);
    });

    test('Single season with no relations returns Season 1 as Current', () {
      final chain = BangumiRemoteDataSource.buildSeasonChain(500, []);
      expect(chain.length, equals(1));
      expect(chain[0].id, equals(500));
      expect(chain[0].name, equals('Season 1'));
      expect(chain[0].isCurrent, isTrue);
    });
  });
}
