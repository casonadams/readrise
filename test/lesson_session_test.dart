import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:readrise/domain/curriculum.dart';
import 'package:readrise/domain/lesson_session.dart';

LessonSession newSession(Skill skill) => LessonSession(
  skill: skill,
  pool: curriculum.lettersThrough(skill),
  random: Random(1),
);

Letter wrongFor(LessonSession s) =>
    s.visibleOptions.firstWhere((o) => o != s.current.target);

void main() {
  final first = curriculum.skills.first;
  final third = curriculum.skills[2];

  test('perfect run earns 3 stars and full XP', () {
    final s = newSession(first);
    while (!s.isComplete) {
      expect(s.answer(s.current.target), isTrue);
    }
    expect(s.stars, 3);
    expect(s.xp, 40);
    expect(s.progress, 1);
  });

  test('wrong pick removes that option and keeps the exercise', () {
    final s = newSession(third);
    final target = s.current.target;
    final before = s.visibleOptions.length;
    final wrong = wrongFor(s);

    expect(s.answer(wrong), isFalse);

    expect(s.current.target, target);
    expect(s.visibleOptions, hasLength(before - 1));
    expect(s.visibleOptions, isNot(contains(wrong)));
    expect(s.mistakes, 1);
  });

  test('missed exercise comes back once, then lesson ends', () {
    final s = newSession(first);
    s.answer(wrongFor(s));
    s.answer(s.current.target);
    var rounds = 0;
    while (!s.isComplete) {
      s.answer(s.current.target);
      rounds++;
    }
    expect(rounds, 4);
    expect(s.stars, 2);
    expect(s.xp, 5 + 10 * 4);
  });

  test('options never exceed maxOptions and always include the target', () {
    final s = newSession(third);
    while (!s.isComplete) {
      expect(s.visibleOptions.length, lessThanOrEqualTo(3));
      expect(s.visibleOptions, contains(s.current.target));
      s.answer(s.current.target);
    }
  });

  test('first skill offers only its own letters', () {
    final s = newSession(first);
    expect(s.current.options.toSet(), first.letters.toSet());
  });
}
