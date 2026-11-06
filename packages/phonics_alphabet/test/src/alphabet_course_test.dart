import 'package:flutter_test/flutter_test.dart';
import 'package:phonics_alphabet/phonics_alphabet.dart';
import 'package:phonics_alphabet/src/letter_lesson.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

void main() {
  final one = AlphabetCourse.set1();
  final two = AlphabetCourse.set2();

  test('each lesson teaches exactly one letter', () {
    expect(one.lessons.map((l) => l.id), ['s', 'a', 't', 'p']);
    expect(two.lessons.map((l) => l.id), ['i', 'n', 'm', 'd']);
    expect(one.lessons.map((l) => l.title), ['Ss', 'Aa', 'Tt', 'Pp']);
  });

  test('set 2 opens only after set 1', () {
    expect(one.requires, isEmpty);
    expect(two.requires, [one.id]);
    expect(one.id, isNot(two.id));
  });

  test('every lesson introduces the letter before quizzing it', () {
    for (final lesson in [...one.lessons, ...two.lessons]) {
      final kinds = lesson.activities.map((a) => a.runtimeType.toString());
      expect(kinds.toList(), ['LetterIntroActivity', 'LetterQuizActivity']);
    }
  });

  test('lesson ids are unique within each course', () {
    for (final CoursePlugin c in [one, two]) {
      final ids = c.lessons.map((l) => l.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    }
  });

  test('letters are real letters with a sound and key word', () {
    for (final lesson in [...one.lessons, ...two.lessons]) {
      final letter = (lesson as LetterLesson).letter;
      expect(letter.char, hasLength(1));
      expect(letter.sound, isNotEmpty);
      expect(letter.word, startsWith(letter.char));
    }
  });
}
