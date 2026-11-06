import 'package:readrise_plugin_api/readrise_plugin_api.dart';

import 'letter.dart';
import 'letter_lesson.dart';
import 'letters.dart';

/// Teaches [letters] one lesson each. [before] are letters taught by earlier
/// courses (review items); [after] are letters not taught yet (distractors
/// when too few letters are known).
class AlphabetCourse implements CoursePlugin {
  AlphabetCourse({
    required this.id,
    required this.title,
    required List<Letter> letters,
    this.grade = Grade.preK,
    this.requires = const [],
    List<Letter> before = const [],
    List<Letter> after = const [],
  }) : lessons = [
         for (var i = 0; i < letters.length; i++)
           LetterLesson(
             letter: letters[i],
             learned: [...before, ...letters.take(i)],
             unseen: [...letters.skip(i + 1), ...after],
           ),
       ];

  factory AlphabetCourse.set1() => AlphabetCourse(
    id: 'alphabet-1',
    title: 'Alphabet 1',
    letters: set1,
    after: set2,
  );

  factory AlphabetCourse.set2() => AlphabetCourse(
    id: 'alphabet-2',
    title: 'Alphabet 2',
    letters: set2,
    requires: const ['alphabet-1'],
    before: set1,
  );

  @override
  final String id;

  @override
  final String title;

  @override
  final Grade grade;

  @override
  Subject get subject => Subject.reading;

  @override
  final List<String> requires;

  @override
  final List<LessonPlugin> lessons;
}
