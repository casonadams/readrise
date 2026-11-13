import 'package:flutter_test/flutter_test.dart';
import 'package:readrise/engine/progress.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

import '../support/fake_plugins.dart';

void main() {
  final registry = buildRegistry();
  final a = registry.courseById(const CourseId('a'));
  final b = registry.courseById(const CourseId('b'));
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

  test('records the last finished lesson', () {
    final p = record(const Progress(), b, b.lessons[1]);
    expect(p.lastLesson, (
      course: const CourseId('b'),
      lesson: const LessonId('5'),
    ));
  });

  test('survives JSON round trip', () {
    final p = record(const Progress(), a, a.lessons[0], mistakes: 1);
    final back = Progress.fromJson(p.toJson());
    expect(back.xp, p.xp);
    expect(back.streak, p.streak);
    expect(back.lastPractice, p.lastPractice);
    expect(back.lastLesson, p.lastLesson);
    expect(back.stars, p.stars);
  });

  test('reads and writes stars under "course/lesson" keys', () {
    final saved = {
      'xp': 30,
      'streak': 2,
      'lastPractice': '2026-03-08T00:00:00.000Z',
      'lastLesson': 'b/5',
      'stars': {'a/1': 3, 'b/5': 1},
    };
    final p = Progress.fromJson(saved);
    expect(p.starsFor(a, a.lessons[0]), 3);
    expect(p.starsFor(b, b.lessons[1]), 1);
    expect(p.toJson(), {...saved, 'items': <String, dynamic>{}});
  });

  test('answers update per-question stats and nothing else', () {
    final before = record(const Progress(), a, a.lessons[0]);
    final p = before.recordAnswers(
      course: a.id,
      answers: const [
        Answer(ItemId('q1'), firstTry: true),
        Answer(ItemId('q2'), firstTry: false),
        Answer(ItemId('q1'), firstTry: true),
      ],
      now: day,
    );
    final stats = p.itemsIn(a.id);
    expect(
      (stats[const ItemId('q1')]!.box, stats[const ItemId('q1')]!.seen),
      (2, 2),
    );
    expect(stats[const ItemId('q2')]!.box, 0);
    expect(p.itemsIn(b.id), isEmpty);
    expect((p.xp, p.streak, p.stars), (before.xp, before.streak, before.stars));
  });

  test('per-question stats survive a JSON round trip', () {
    final p = const Progress().recordAnswers(
      course: a.id,
      answers: const [Answer(ItemId('q1'), firstTry: true)],
      now: day,
    );
    final back = Progress.fromJson(p.toJson())
        .itemsIn(a.id)[const ItemId('q1')]!;
    expect(
      (back.seen, back.firstTries, back.box, back.lastSeen),
      (1, 1, 1, day),
    );
  });
}
