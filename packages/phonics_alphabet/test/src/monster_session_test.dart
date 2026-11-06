import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:phonics_alphabet/src/letters.dart';
import 'package:phonics_alphabet/src/monster_session.dart';

import '../support/letters.dart';

MonsterSession sessionFor(String c, {int seed = 1}) => MonsterSession(
  letter: letterOf(c),
  learned: before(c),
  unseen: after(c),
  random: Random(seed),
);

List<Food> drain(MonsterSession s, {void Function(Food)? each}) {
  final seen = <Food>[];
  while (!s.isComplete) {
    final f = s.current;
    seen.add(f);
    each?.call(f);
    s.answer(feed: f.edible);
  }
  return seen;
}

void main() {
  test('serves six foods: the letter\'s own pictures plus others', () {
    final foods = drain(sessionFor('s'));
    expect(foods, hasLength(6));
    expect(foods.where((f) => f.edible), hasLength(3));
    expect(foods.where((f) => f.edible).map((f) => f.picture.word).toSet(), {
      'sun',
      'sock',
      'snake',
    });
  });

  test('a letter with a single picture still fills the plate', () {
    final foods = drain(sessionFor('u'));
    expect(foods.where((f) => f.edible), hasLength(1));
    expect(foods, hasLength(6));
  });

  test('foods are never the same picture twice', () {
    for (var seed = 0; seed < 20; seed++) {
      final words = drain(sessionFor('m', seed: seed))
          .map((f) => f.picture.word)
          .toList();
      expect(words.toSet(), hasLength(words.length));
    }
  });

  test('what it should not eat never starts with the letter', () {
    for (final c in allLetters.where((l) => l.startsWord).map((l) => l.char)) {
      for (var seed = 0; seed < 5; seed++) {
        for (final f in drain(
          sessionFor(c, seed: seed),
        ).where((f) => !f.edible)) {
          expect(
            f.picture.word,
            isNot(startsWith(c)),
            reason: '$c: ${f.picture.word}',
          );
        }
      }
    }
  });

  for (final (letter, banned) in [
    ('b', 'd'),
    ('d', 'b'),
    ('p', 'q'),
    ('q', 'p'),
  ]) {
    test('while $letter is new, no $banned pictures are served', () {
      for (var seed = 0; seed < 20; seed++) {
        for (final f in drain(
          sessionFor(letter, seed: seed),
        ).where((f) => !f.edible)) {
          expect(f.picture.word, isNot(startsWith(banned)));
        }
      }
    });
  }

  for (final (letter, banned) in [
    ('c', 'k'),
    ('k', 'c'),
    ('c', 'q'),
    ('q', 'c'),
  ]) {
    test('$letter never gets $banned words, which sound the same', () {
      for (var seed = 0; seed < 20; seed++) {
        for (final f in drain(
          sessionFor(letter, seed: seed),
        ).where((f) => !f.edible)) {
          expect(f.picture.word, isNot(startsWith(banned)));
        }
      }
    });
  }

  test('the first lesson borrows pictures from letters not taught yet', () {
    final others = drain(sessionFor('s')).where((f) => !f.edible);
    expect(others, hasLength(3));
    for (final f in others) {
      expect(f.picture.word, isNot(startsWith('s')));
    }
  });

  test('x cannot be fed, because no word starts with it', () {
    expect(
      () => MonsterSession(letter: letterOf('x')),
      throwsA(isA<AssertionError>()),
    );
  });

  group('answering', () {
    test('a perfect plate earns full XP', () {
      final s = sessionFor('s');
      drain(s);
      expect(s.xp, 30);
      expect(s.mistakes, 0);
      expect(s.progress, 1);
    });

    test('feeding the wrong thing is a mistake and the food stays', () {
      final s = sessionFor('s');
      final food = s.current;
      expect(s.answer(feed: !food.edible), isFalse);
      expect(s.current, same(food));
      expect(s.mistakes, 1);
    });

    test('a missed food comes back once, at reduced credit', () {
      final s = sessionFor('s');
      final first = s.current;
      s.answer(feed: !first.edible);
      var served = 0;
      while (!s.isComplete) {
        served++;
        s.answer(feed: s.current.edible);
      }
      expect(served, 7);
      expect(s.mistakes, 1);
      expect(s.xp, 5 * 5 + 2, reason: 'the practice round earns nothing');
    });
  });
}
