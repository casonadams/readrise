import 'package:flutter_test/flutter_test.dart';
import 'package:readrise/engine/attempt.dart';
import 'package:readrise/engine/item_stats.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

import '../support/fake_plugins.dart';

String _label(ActivityPlugin a) => (a as FakeActivity).label;

void main() {
  const fixed = FakeActivity('fixed');
  const review = FakeReview(
    'warm-up',
    reviewable: [ItemId('q1'), ItemId('q2')],
  );
  final lesson = FakeLesson(
    '1',
    activities: const [review, FakeShufflingActivity('a'), fixed],
  );
  final hardQ2 = {
    const ItemId('q1'): ItemStats(
      seen: 1,
      firstTries: 1,
      box: 1,
      lastSeen: DateTime(2026),
    ),
    const ItemId('q2'): ItemStats(
      seen: 1,
      firstTries: 0,
      box: 0,
      lastSeen: DateTime(2026),
    ),
  };
  List<String> labels(int seed, Map<ItemId, ItemStats> stats) => [
    for (final a in attemptActivities(lesson, seed: seed, stats: stats))
      _label(a),
  ];

  test('keeps the lesson order and leaves fixed activities as they are', () {
    final activities = attemptActivities(lesson, seed: 1, stats: const {});
    expect(activities, hasLength(3));
    expect(activities[2], same(fixed));
    expect(_label(activities[1]), startsWith('a '));
  });

  test('each attempt arranges activities by its own seed', () {
    expect(labels(1, const {}), labels(1, const {}));
    expect(labels(1, const {})[1], isNot(labels(2, const {})[1]));
  });

  test('a review asks the hardest answered items, or stays as written', () {
    expect(labels(1, const {})[0], 'warm-up');
    expect(labels(1, hardQ2)[0], 'reviewing q2');
  });

  test("what a review picks never changes another activity's arrangement", () {
    expect(labels(5, hardQ2)[1], labels(5, const {})[1]);
  });
}
