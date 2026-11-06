import 'package:flutter_test/flutter_test.dart';
import 'package:readrise/domain/curriculum.dart';
import 'package:readrise/domain/progress.dart';

import 'support/fixtures.dart';

void main() {
  final curriculum = buildCurriculum();
  final a = curriculum.courseById('a');
  final b = curriculum.courseById('b');
  final day = DateTime(2026, 3, 8);

  Progress record(Progress p, Lesson l, int stars, DateTime when) =>
      p.recordLesson(lesson: l, earnedStars: stars, earnedXp: 10, today: when);

  Progress completeCourse(Progress p, Course c) => [
    for (final l in c.lessons) l,
  ].fold(p, (acc, l) => record(acc, l, 1, day));

  test('lessons unlock in order within a course', () {
    var p = const Progress();
    expect(p.isLessonUnlocked(curriculum, a, a.lessons[0]), isTrue);
    expect(p.isLessonUnlocked(curriculum, a, a.lessons[1]), isFalse);

    p = record(p, a.lessons[0], 1, day);
    expect(p.isLessonUnlocked(curriculum, a, a.lessons[1]), isTrue);
    expect(p.isLessonUnlocked(curriculum, a, a.lessons[2]), isFalse);
  });

  test('a course stays locked until every required course is complete', () {
    var p = const Progress();
    expect(p.isCourseUnlocked(curriculum, a), isTrue);
    expect(p.isCourseUnlocked(curriculum, b), isFalse);
    expect(p.isLessonUnlocked(curriculum, b, b.lessons[0]), isFalse);

    p = record(p, a.lessons[0], 3, day);
    p = record(p, a.lessons[1], 3, day);
    expect(p.isCourseUnlocked(curriculum, b), isFalse);

    p = record(p, a.lessons[2], 1, day);
    expect(p.isCourseComplete(a), isTrue);
    expect(p.isCourseUnlocked(curriculum, b), isTrue);
    expect(p.isLessonUnlocked(curriculum, b, b.lessons[0]), isTrue);
    expect(p.isLessonUnlocked(curriculum, b, b.lessons[1]), isFalse);
  });

  test('stars keep the best result; XP accumulates', () {
    var p = record(const Progress(), a.lessons[0], 3, day);
    p = record(p, a.lessons[0], 1, day);
    expect(p.starsFor(a.lessons[0]), 3);
    expect(p.xp, 20);
  });

  test('streak: same day holds, next day grows, gap resets', () {
    var p = record(const Progress(), a.lessons[0], 1, DateTime(2026, 3, 8));
    p = record(p, a.lessons[0], 1, DateTime(2026, 3, 8, 20));
    expect(p.streak, 1);
    p = record(p, a.lessons[0], 1, DateTime(2026, 3, 9));
    expect(p.streak, 2);
    p = record(p, a.lessons[0], 1, DateTime(2026, 3, 12));
    expect(p.streak, 1);
  });

  test('displayed streak lapses after a missed day', () {
    final p = record(const Progress(), a.lessons[0], 1, DateTime(2026, 3, 8));
    expect(p.streakOn(DateTime(2026, 3, 9)), 1);
    expect(p.streakOn(DateTime(2026, 3, 10)), 0);
  });

  test('survives JSON round trip', () {
    final p = completeCourse(const Progress(), a);
    final back = Progress.fromJson(p.toJson());
    expect(back.xp, p.xp);
    expect(back.streak, p.streak);
    expect(back.lastPractice, p.lastPractice);
    expect(back.stars, p.stars);
  });
}
