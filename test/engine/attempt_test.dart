import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:readrise/engine/attempt.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

import '../support/fake_plugins.dart';

/// Reports, as its label, the first number the attempt's random gave it.
class _Shuffles extends FakeActivity implements Randomizable {
  const _Shuffles(super.label);

  @override
  ActivityPlugin shuffled(Random random) =>
      FakeActivity('$label ${random.nextInt(1000)}');
}

void main() {
  final fixed = const FakeActivity('fixed');
  final lesson = FakeLesson(
    '1',
    activities: [const _Shuffles('a'), fixed, const _Shuffles('b')],
  );
  List<String> labels(int seed) => [
    for (final a in attemptActivities(lesson, Random(seed)))
      (a as FakeActivity).label,
  ];

  test('keeps the lesson order and leaves fixed activities as they are', () {
    final activities = attemptActivities(lesson, Random(1));
    expect(activities, hasLength(3));
    expect(activities[1], same(fixed));
    expect((activities[0] as FakeActivity).label, startsWith('a '));
    expect((activities[2] as FakeActivity).label, startsWith('b '));
  });

  test('each attempt arranges activities by its own seed', () {
    expect(labels(1), labels(1));
    expect(labels(1), isNot(labels(2)));
  });
}
