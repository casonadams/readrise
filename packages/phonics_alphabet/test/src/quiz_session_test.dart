import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:phonics_alphabet/src/letter.dart';
import 'package:phonics_alphabet/src/letters.dart';
import 'package:phonics_alphabet/src/quiz_session.dart';

import '../support/letters.dart';

QuizSession lessonFor(String c, {int seed = 1}) => QuizSession.lesson(
  letter: letterOf(c),
  learned: before(c),
  unseen: after(c),
  random: Random(seed),
);

Letter wrongFor(QuizSession q) =>
    q.current.options.firstWhere((o) => o != q.current.target);

List<Exercise> drain(QuizSession q) {
  final seen = <Exercise>[];
  while (!q.isComplete) {
    seen.add(q.current);
    q.answer(q.current.target);
  }
  return seen;
}

void main() {
  group('lesson quiz', () {
    test('asks the new letter three times and reviews the last two', () {
      final targets = drain(lessonFor('t')).map((e) => e.target.char).toList();
      expect(targets.where((c) => c == 't'), hasLength(3));
      expect(targets.toSet(), {'t', 'a', 's'});
      expect(targets, hasLength(5));
    });

    test('the very first lesson only has its own letter to ask', () {
      final targets = drain(lessonFor('s')).map((e) => e.target.char);
      expect(targets.toSet(), {'s'});
    });

    test('with nothing learned yet, wrong answers are untaught letters', () {
      final q = lessonFor('s');
      expect(q.current.options, hasLength(3));
      expect(
        q.current.options.toSet().difference({letterOf('s')}),
        everyElement(isIn(after('s'))),
      );
    });

    test('later lessons draw wrong answers from learned letters only', () {
      for (final e in drain(lessonFor('t'))) {
        expect(
          e.options.map((l) => l.char).toSet().difference({'s', 'a', 't'}),
          isEmpty,
        );
      }
    });

    test('alternates hearing a letter and seeing a picture', () {
      final kinds = drain(lessonFor('t')).map((e) => e.kind).toList();
      expect(kinds.take(2), [
        ExerciseKind.soundToLetter,
        ExerciseKind.pictureToLetter,
      ]);
    });

    test('three choices early, four once eight letters are known', () {
      expect(lessonFor('i').current.options, hasLength(3));
      expect(lessonFor('g').current.options, hasLength(4));
      expect(lessonFor('z').current.options, hasLength(4));
    });

    for (final (mirror, twin) in [
      ('b', 'd'),
      ('q', 'p'),
      ('d', 'b'),
      ('p', 'q'),
    ]) {
      test('while $mirror is new, $twin never appears among the choices', () {
        for (var seed = 0; seed < 30; seed++) {
          for (final e in drain(lessonFor(mirror, seed: seed))) {
            expect(
              e.options.map((l) => l.char),
              isNot(contains(twin)),
              reason: 'seed $seed',
            );
          }
        }
      });
    }

    test('x is only ever asked by sound; other letters still get pictures', () {
      final asked = drain(lessonFor('x'));
      for (final e in asked.where((e) => e.target.char == 'x')) {
        expect(e.kind, ExerciseKind.soundToLetter);
      }
      expect(asked.any((e) => e.kind == ExerciseKind.pictureToLetter), isTrue);
    });
  });

  group('review quiz', () {
    final set = letterSets[1];
    QuizSession review({int seed = 3}) => QuizSession.review(
      letters: set,
      known: [...letterSets[0], ...set],
      random: Random(seed),
    );

    test('asks every letter of the set once by sound and once by picture', () {
      final seen = drain(review());
      expect(seen, hasLength(set.length * 2));
      for (final l in set) {
        expect(seen.where((e) => e.target == l).map((e) => e.kind).toSet(), {
          ExerciseKind.soundToLetter,
          ExerciseKind.pictureToLetter,
        });
      }
    });

    test('is shuffled, not in lesson order', () {
      final orders = {
        for (var s = 0; s < 10; s++)
          drain(review(seed: s)).map((e) => e.target.char).join(),
      };
      expect(orders.length, greaterThan(1));
    });

    test('mirror twins may appear together once everything is taught', () {
      var sawBoth = false;
      final q = QuizSession.review(
        letters: [letterOf('b'), letterOf('d')],
        known: [letterOf('b'), letterOf('d'), letterOf('s'), letterOf('a')],
        random: Random(1),
      );
      for (final e in drain(q)) {
        final chars = e.options.map((l) => l.char);
        if (chars.contains('b') && chars.contains('d')) sawBoth = true;
      }
      expect(sawBoth, isTrue);
    });
  });

  group('answering', () {
    test('a perfect run: full XP, no mistakes, progress complete', () {
      final q = lessonFor('s');
      drain(q);
      expect(q.xp, 30);
      expect(q.mistakes, 0);
      expect(q.progress, 1);
    });

    test('a wrong pick is crossed out in place and the question stays', () {
      final q = lessonFor('t');
      final target = q.current.target;
      final options = [...q.current.options];
      final wrong = wrongFor(q);

      expect(q.answer(wrong), isFalse);

      expect(q.current.target, target);
      expect(q.current.options, options, reason: 'options keep their places');
      expect(q.isEliminated(wrong), isTrue);
      expect(q.visibleOptions, isNot(contains(wrong)));
      expect(q.mistakes, 1);
    });

    test('the cross-outs clear for the next question', () {
      final q = lessonFor('t');
      final wrong = wrongFor(q);
      q.answer(wrong);
      q.answer(q.current.target);
      expect(q.isEliminated(wrong), isFalse);
    });

    test('a missed question comes back once, at half credit', () {
      final q = lessonFor('s');
      q.answer(wrongFor(q));
      q.answer(q.current.target);
      var rounds = 0;
      while (!q.isComplete) {
        q.answer(q.current.target);
        rounds++;
      }
      expect(rounds, 3);
      expect(q.mistakes, 1);
      expect(q.xp, 5 + 10 * 2, reason: 'the practice round earns nothing');
    });
  });
}
