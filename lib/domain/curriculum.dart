class Letter {
  const Letter({
    required this.char,
    required this.sound,
    required this.word,
    required this.emoji,
  });

  final String char;
  final String sound;
  final String word;
  final String emoji;

  String get upper => char.toUpperCase();
  String get display => '$upper$char';
}

enum Grade { preK, kindergarten, grade1 }

sealed class Lesson {
  const Lesson({required this.id, required this.title});

  final String id;
  final String title;
}

/// Teaches one letter: its shape, sound and a key word.
class LetterLesson extends Lesson {
  LetterLesson({required super.id, required this.letter})
    : super(title: letter.display);

  final Letter letter;
}

class Course {
  const Course({
    required this.id,
    required this.title,
    required this.grade,
    required this.lessons,
    this.requires = const [],
  });

  final String id;
  final String title;
  final Grade grade;
  final List<Lesson> lessons;

  /// Ids of courses that must be complete before this one opens.
  final List<String> requires;
}

class Curriculum {
  Curriculum({required this.id, required this.title, required this.courses})
    : _lessons = {
        for (final c in courses)
          for (final l in c.lessons) l.id: l,
      };

  final String id;
  final String title;
  final List<Course> courses;
  final Map<String, Lesson> _lessons;

  Iterable<Lesson> get lessons => courses.expand((c) => c.lessons);

  Course courseById(String id) => courses.firstWhere((c) => c.id == id);

  Lesson lessonById(String id) =>
      _lessons[id] ?? (throw ArgumentError.value(id, 'id', 'unknown lesson'));

  /// Letters taught by lessons that precede [lesson] across all courses.
  List<Letter> lettersBefore(Lesson lesson) => [
    for (final l in lessons.takeWhile((l) => l != lesson))
      if (l case LetterLesson(:final letter)) letter,
  ];

  /// Letters taught by lessons that follow [lesson] across all courses.
  List<Letter> lettersAfter(Lesson lesson) => [
    for (final l in lessons.skipWhile((l) => l != lesson).skip(1))
      if (l case LetterLesson(:final letter)) letter,
  ];
}
