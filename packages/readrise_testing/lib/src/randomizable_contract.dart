import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

/// The rules every [Randomizable] activity follows, as tests. [arrangement]
/// lists what may move, in the order the learner sees it: questions,
/// choices, claims or items.
void randomizableContract<A extends ActivityPlugin>(
  String name,
  A activity, {
  required List<Object?> Function(A activity) arrangement,
}) {
  List<Object?> attempt(int seed) =>
      arrangement((activity as Randomizable).shuffled(Random(seed)) as A);

  group('$name shuffling', () {
    test('keeps every part, so each choice keeps its feedback', () {
      final original = arrangement(activity);
      for (var seed = 0; seed < 20; seed++) {
        expect(attempt(seed), unorderedEquals(original), reason: 'seed $seed');
      }
    });

    test('arranges the same way for the same seed', () {
      expect(attempt(7), attempt(7));
    });

    test('arranges differently across attempts', () {
      final first = attempt(0);
      expect(
        [for (var seed = 1; seed < 20; seed++) attempt(seed)],
        anyElement(isNot(equals(first))),
      );
    });
  });
}
