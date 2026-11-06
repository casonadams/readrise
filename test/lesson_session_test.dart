import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:readrise/domain/curriculum.dart';
import 'package:readrise/domain/lesson_session.dart';

import 'support/fixtures.dart';

final curriculum = buildCurriculum();

LessonSession newSession(String id) {
  final lesson = curriculum.lessonById(id) as LetterLesson;
  return LessonSession(
    lesson: lesson,
    learned: curriculum.lettersBefore(lesson),
    unseen: curriculum.lettersAfter(lesson),
    random: Random(1),
  );
}

Letter wrongFor(LessonSession s) =>
    s.visibleOptions.firstWhere((o) => o != s.current.target);

List<Letter> targetsOf(LessonSession s) {
  final targets = <Letter>[];
  while (!s.isComplete) {
    targets.add(s.current.target);
    s.answer(s.current.target);
  }
  return targets;
}

void main() {
  final s = (curriculum.lessonById('l-s') as LetterLesson).letter;
  final a = (curriculum.lessonById('l-a') as LetterLesson).letter;
  final t = (curriculum.lessonById('l-t') as LetterLesson).letter;
  final i = (curriculum.lessonById('l-i') as LetterLesson).letter;

  test('first lesson drills only its single letter', () {
    expect(targetsOf(newSession('l-s')).toSet(), {s});
  });

  test('first lesson still offers a choice using letters not yet taught', () {
    final session = newSession('l-s');
    expect(session.current.options, hasLength(3));
    expect(session.current.options, contains(s));
  });

  test('later lesson reviews the two most recent letters across courses', () {
    final targets = targetsOf(newSession('l-i'));
    expect(targets.toSet(), {
      i,
      curriculum.lettersBefore(curriculum.lessonById('l-i')).last,
      t,
    });
    expect(targets.where((x) => x == i), hasLength(3));
  });

  test('later lesson distractors come from taught letters only', () {
    final session = newSession('l-t');
    final allowed = {s, a, t};
    while (!session.isComplete) {
      expect(allowed.containsAll(session.current.options), isTrue);
      session.answer(session.current.target);
    }
  });

  test('perfect run earns 3 stars and full XP', () {
    final session = newSession('l-s');
    while (!session.isComplete) {
      expect(session.answer(session.current.target), isTrue);
    }
    expect(session.stars, 3);
    expect(session.xp, 30);
    expect(session.progress, 1);
  });

  test('wrong pick removes that option and keeps the exercise', () {
    final session = newSession('l-t');
    final target = session.current.target;
    final before = session.visibleOptions.length;
    final wrong = wrongFor(session);

    expect(session.answer(wrong), isFalse);

    expect(session.current.target, target);
    expect(session.visibleOptions, hasLength(before - 1));
    expect(session.visibleOptions, isNot(contains(wrong)));
    expect(session.mistakes, 1);
  });

  test('missed exercise comes back once, then lesson ends', () {
    final session = newSession('l-s');
    session.answer(wrongFor(session));
    session.answer(session.current.target);
    var rounds = 0;
    while (!session.isComplete) {
      session.answer(session.current.target);
      rounds++;
    }
    expect(rounds, 3);
    expect(session.stars, 2);
    expect(session.xp, 5 + 10 * 3);
  });
}
