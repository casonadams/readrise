import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:readrise/engine/item_stats.dart';
import 'package:readrise/engine/review.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

ItemStats _stats(int box, int day) => ItemStats(
  seen: 1,
  firstTries: 0,
  box: box,
  lastSeen: DateTime(2026, 3, day),
);

void main() {
  const pool = [ItemId('a'), ItemId('b'), ItemId('c'), ItemId('d')];

  test('reviews the hardest items first, then the longest unseen', () {
    final stats = {
      const ItemId('a'): _stats(3, 1),
      const ItemId('b'): _stats(0, 9),
      const ItemId('c'): _stats(1, 2),
      const ItemId('d'): _stats(1, 5),
    };
    for (var seed = 0; seed < 10; seed++) {
      expect(pickForReview(pool, 3, stats, Random(seed)), [
        const ItemId('b'),
        const ItemId('c'),
        const ItemId('d'),
      ]);
    }
  });

  test('ignores unanswered items and items outside the pool', () {
    final stats = {
      const ItemId('a'): _stats(2, 1),
      const ItemId('c'): _stats(4, 1),
      const ItemId('z'): _stats(0, 1),
    };
    expect(
      pickForReview(pool, 2, stats, Random(1)),
      unorderedEquals([const ItemId('a'), const ItemId('c')]),
    );
  });

  test('gives up when too few items have been answered', () {
    expect(
      pickForReview(pool, 2, {const ItemId('a'): _stats(0, 1)}, Random(1)),
      isNull,
    );
  });

  test('breaks ties at random', () {
    final tied = {for (final id in pool) id: _stats(0, 1)};
    expect({
      for (var seed = 0; seed < 20; seed++)
        pickForReview(pool, 1, tied, Random(seed))!.single,
    }, hasLength(greaterThan(1)));
  });
}
