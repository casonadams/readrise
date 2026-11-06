import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:phonics_alphabet/src/letter.dart';
import 'package:phonics_alphabet/src/letters.dart';
import 'package:phonics_alphabet/src/quiz_session.dart';

final s = set1[0], a = set1[1], t = set1[2];

QuizSession newSession(
  Letter letter, {
  List<Letter> learned = const [],
  List<Letter> unseen = const [],
}) => QuizSession(
  letter: letter,
  learned: learned,
  unseen: unseen,
  random: Random(1),
);

Letter wrongFor(QuizSession q) =>
    q.visibleOptions.firstWhere((o) => o != q.current.target);

List<Letter> targetsOf(QuizSession q) {
  final targets = <Letter>[];
  while (!q.isComplete) {
    targets.add(q.current.target);
    q.answer(q.current.target);
  }
  return targets;
}

void main() {
  test('first lesson drills only its single letter', () {
    final q = newSession(s, unseen: [a, t]);
    expect(targetsOf(q).toSet(), {s});
  });

  test('with nothing learned yet, distractors are letters not yet taught', () {
    final q = newSession(s, unseen: [a, t]);
    expect(q.current.options, hasLength(3));
    expect(q.current.options.toSet(), {s, a, t});
  });

  test('later lesson reviews the two most recent letters', () {
    final q = newSession(t, learned: [s, a]);
    final targets = targetsOf(q);
    expect(targets.toSet(), {t, a, s});
    expect(targets.where((x) => x == t), hasLength(3));
  });

  test('distractors come from taught letters when enough are known', () {
    final q = newSession(t, learned: [s, a], unseen: [set1[3]]);
    while (!q.isComplete) {
      expect(q.current.options.toSet(), {s, a, t});
      q.answer(q.current.target);
    }
  });

  test('perfect run: full XP, no mistakes, progress complete', () {
    final q = newSession(s, unseen: [a, t]);
    while (!q.isComplete) {
      expect(q.answer(q.current.target), isTrue);
    }
    expect(q.xp, 30);
    expect(q.mistakes, 0);
    expect(q.progress, 1);
  });

  test('wrong pick removes that option and keeps the exercise', () {
    final q = newSession(t, learned: [s, a]);
    final target = q.current.target;
    final before = q.visibleOptions.length;
    final wrong = wrongFor(q);

    expect(q.answer(wrong), isFalse);

    expect(q.current.target, target);
    expect(q.visibleOptions, hasLength(before - 1));
    expect(q.visibleOptions, isNot(contains(wrong)));
    expect(q.mistakes, 1);
  });

  test('missed exercise comes back once, then the quiz ends', () {
    final q = newSession(s, unseen: [a, t]);
    q.answer(wrongFor(q));
    q.answer(q.current.target);
    var rounds = 0;
    while (!q.isComplete) {
      q.answer(q.current.target);
      rounds++;
    }
    expect(rounds, 3);
    expect(q.mistakes, 1);
    expect(q.xp, 5 + 10 * 3);
  });
}
