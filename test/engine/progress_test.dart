import 'package:flutter_test/flutter_test.dart';
import 'package:readrise/engine/progress.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

import '../support/fake_plugins.dart';

void main() {
  final registry = buildRegistry();
  final a = registry.courseById('a');
  final b = registry.courseById('b');
  final day = DateTime(2026, 3, 8);

  Progress record(
    Progress p,
    CoursePlugin course,
    LessonPlugin lesson, {
    int mistakes = 0,
    int xp = 10,
    DateTime? when,
  }) => p.recordLesson(
    course: course,
    lesson: lesson,
    outcome: LessonOutcome(xp: xp, mistakes: mistakes),
    today: when ?? day,
  );

  group('LessonOutcome.stars', () {
    final cases = {0: 3, 1: 2, 2: 2, 3: 1, 9: 1};
    cases.forEach((mistakes, stars) {
      test('$mistakes mistakes -> $stars stars', () {
        expect(LessonOutcome(xp: 0, mistakes: mistakes).stars, stars);
      });
    });
  });

  test('lessons unlock in order within a course', () {
    var p = const Progress();
    expect(p.isLessonUnlocked(registry, a, a.lessons[0]), isTrue);
    expect(p.isLessonUnlocked(registry, a, a.lessons[1]), isFalse);

    p = record(p, a, a.lessons[0]);
    expect(p.isLessonUnlocked(registry, a, a.lessons[1]), isTrue);
    expect(p.isLessonUnlocked(registry, a, a.lessons[2]), isFalse);
  });

  test('a course stays locked until every required course is complete', () {
    var p = const Progress();
    expect(p.isCourseUnlocked(registry, a), isTrue);
    expect(p.isCourseUnlocked(registry, b), isFalse);
    expect(p.isLessonUnlocked(registry, b, b.lessons[0]), isFalse);

    p = record(p, a, a.lessons[0]);
    p = record(p, a, a.lessons[1]);
    expect(p.isCourseUnlocked(registry, b), isFalse);

    p = record(p, a, a.lessons[2], mistakes: 5);
    expect(p.isCourseComplete(a), isTrue);
    expect(p.isCourseUnlocked(registry, b), isTrue);
    expect(p.isLessonUnlocked(registry, b, b.lessons[0]), isTrue);
    expect(p.isLessonUnlocked(registry, b, b.lessons[1]), isFalse);
  });

  test('progress is tracked per course, not by lesson id alone', () {
    final other = FakeCourse('z', ['1']);
    final p = record(const Progress(), a, a.lessons[0]);
    expect(p.starsFor(a, a.lessons[0]), 3);
    expect(p.starsFor(other, other.lessons[0]), 0);
  });

  test('stars keep the best result; XP accumulates', () {
    var p = record(const Progress(), a, a.lessons[0]);
    p = record(p, a, a.lessons[0], mistakes: 4);
    expect(p.starsFor(a, a.lessons[0]), 3);
    expect(p.xp, 20);
  });

  test('streak: same day holds, next day grows, gap resets', () {
    var p = record(
      const Progress(),
      a,
      a.lessons[0],
      when: DateTime(2026, 3, 8),
    );
    p = record(p, a, a.lessons[0], when: DateTime(2026, 3, 8, 20));
    expect(p.streak, 1);
    p = record(p, a, a.lessons[0], when: DateTime(2026, 3, 9));
    expect(p.streak, 2);
    p = record(p, a, a.lessons[0], when: DateTime(2026, 3, 12));
    expect(p.streak, 1);
  });

  test('displayed streak lapses after a missed day', () {
    final p = record(const Progress(), a, a.lessons[0]);
    expect(p.streakOn(DateTime(2026, 3, 9)), 1);
    expect(p.streakOn(DateTime(2026, 3, 10)), 0);
  });

  test('survives JSON round trip', () {
    final p = record(const Progress(), a, a.lessons[0], mistakes: 1);
    final back = Progress.fromJson(p.toJson());
    expect(back.xp, p.xp);
    expect(back.streak, p.streak);
    expect(back.lastPractice, p.lastPractice);
    expect(back.stars, p.stars);
  });
}
