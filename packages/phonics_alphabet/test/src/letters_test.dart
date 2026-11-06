import 'package:flutter_test/flutter_test.dart';
import 'package:phonics_alphabet/src/letter.dart';
import 'package:phonics_alphabet/src/letters.dart';

void main() {
  test('teaches each of the 26 letters exactly once', () {
    expect(allLetters.map((l) => l.char).join(), hasLength(26));
    expect(allLetters.map((l) => l.char).toSet(), {
      for (var c = 0; c < 26; c++) String.fromCharCode(97 + c),
    });
  });

  test('starts with the Letters and Sounds order', () {
    expect(allLetters.take(12).map((l) => l.char).join(), 'satpinmdgock');
  });

  test('sets are small enough to learn in one sitting', () {
    for (final set in letterSets) {
      expect(set.length, inInclusiveRange(3, 4));
    }
  });

  test('every picture word starts with its letter, except x', () {
    for (final l in allLetters) {
      for (final p in l.pictures) {
        if (l.char == 'x') continue;
        expect(p.word, startsWith(l.char), reason: '${l.char}: ${p.word}');
      }
    }
    expect(letterOf('x').startsWord, isFalse);
    expect(allLetters.where((l) => !l.startsWord).map((l) => l.char), ['x']);
  });

  test('x teaches with a word that ends in it, highlighting the x', () {
    final x = letterOf('x');
    expect(x.word, endsWith('x'));
    expect(x.word[x.highlightIndex], 'x');
    expect(letterOf('a').highlightIndex, 0);
  });

  test('no picture or word is used by two letters', () {
    final words = [
      for (final l in allLetters) ...l.pictures.map((p) => p.word),
    ];
    final emoji = [
      for (final l in allLetters) ...l.pictures.map((p) => p.emoji),
    ];
    expect(words.toSet(), hasLength(words.length));
    expect(emoji.toSet(), hasLength(emoji.length));
  });

  test('mirror and sound-twin letters are flagged', () {
    expect(letterOf('b').mirrorChar, 'd');
    expect(letterOf('q').mirrorChar, 'p');
    expect(letterOf('s').mirrorChar, isNull);
    expect(letterOf('c').soundTwins, {'k', 'q'});
    expect(letterOf('s').soundTwins, isEmpty);
  });
}

Letter letterOf(String c) => allLetters.firstWhere((l) => l.char == c);
