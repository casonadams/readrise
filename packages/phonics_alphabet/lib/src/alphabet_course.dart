import 'package:readrise_plugin_api/readrise_plugin_api.dart';

import 'letter.dart';
import 'letter_lesson.dart';
import 'letters.dart';

/// One set of letters: a lesson per letter and a review at the end.
/// [before] are letters from earlier courses (review items); [after] are
/// letters not taught yet (wrong-answer pool when too few are known).
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
         ReviewLesson(letters: letters, known: [...before, ...letters]),
       ];

  /// The whole alphabet as seven courses in teaching order.
  static List<AlphabetCourse> all() => [
    for (var n = 0; n < letterSets.length; n++)
      AlphabetCourse(
        id: CourseId('alphabet-${n + 1}'),
        title:
            'Alphabet ${n + 1}: '
            '${letterSets[n].map((l) => l.upper).join(' ')}',
        letters: letterSets[n],
        grade: n < 4 ? Grade.preK : Grade.kindergarten,
        requires: n == 0 ? const [] : [CourseId('alphabet-$n')],
        before: [for (final s in letterSets.take(n)) ...s],
        after: [for (final s in letterSets.skip(n + 1)) ...s],
      ),
  ];

  @override
  final CourseId id;

  @override
  final String title;

  @override
  final Grade grade;

  @override
  Subject get subject => Subject.reading;

  @override
  final List<CourseId> requires;

  @override
  final List<LessonPlugin> lessons;
}
