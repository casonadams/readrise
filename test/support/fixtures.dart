import 'package:readrise/domain/curriculum.dart';

LetterLesson letterLesson(String char) => LetterLesson(
  id: 'l-$char',
  letter: Letter(
    char: char,
    sound: '$char-sound',
    word: '$char-word',
    emoji: char,
  ),
);

/// Course "a": s, a, t. Course "b" (requires "a"): p, i.
Curriculum buildCurriculum() => Curriculum(
  id: 'test',
  title: 'Test',
  courses: [
    Course(
      id: 'a',
      title: 'A',
      grade: Grade.preK,
      lessons: [letterLesson('s'), letterLesson('a'), letterLesson('t')],
    ),
    Course(
      id: 'b',
      title: 'B',
      grade: Grade.preK,
      requires: const ['a'],
      lessons: [letterLesson('p'), letterLesson('i')],
    ),
  ],
);
