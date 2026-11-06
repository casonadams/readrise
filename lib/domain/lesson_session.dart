import 'dart:collection';
import 'dart:math';

import 'curriculum.dart';

enum ExerciseKind { soundToLetter, pictureToLetter }

class Exercise {
  const Exercise({
    required this.kind,
    required this.target,
    required this.options,
  });

  final ExerciseKind kind;
  final Letter target;
  final List<Letter> options;
}

class LessonSession {
  LessonSession({
    required LetterLesson lesson,
    this.learned = const [],
    this.unseen = const [],
    Random? random,
    this.maxOptions = 3,
  }) : _random = random ?? Random() {
    final letter = lesson.letter;
    final targets = [letter, letter, ...learned.reversed.take(2), letter];
    for (var i = 0; i < targets.length; i++) {
      _queue.add(
        _build(ExerciseKind.values[i % 2], targets[i], [...learned, letter]),
      );
    }
  }

  /// Letters from earlier lessons: review targets and preferred distractors.
  final List<Letter> learned;

  /// Letters not taught yet; distractors only when too few learned exist.
  final List<Letter> unseen;
  final int maxOptions;
  final Random _random;
  final Queue<Exercise> _queue = Queue();
  final Set<Letter> _eliminated = {};
  final Set<Exercise> _retried = {};
  bool _currentMissed = false;
  int _firstTry = 0;
  int _recovered = 0;
  int mistakes = 0;

  bool get isComplete => _queue.isEmpty;
  Exercise get current => _queue.first;
  int get completed => _firstTry + _recovered;
  double get progress => completed / (completed + _queue.length);
  int get xp => _firstTry * 10 + _recovered * 5;

  /// Options still shown; wrong picks are removed so the choice narrows.
  List<Letter> get visibleOptions => [
    for (final o in current.options)
      if (!_eliminated.contains(o)) o,
  ];

  int get stars => switch (mistakes) {
    0 => 3,
    <= 2 => 2,
    _ => 1,
  };

  /// Returns true when [choice] is correct and the lesson advanced.
  bool answer(Letter choice) {
    final exercise = current;
    if (choice == exercise.target) {
      _queue.removeFirst();
      if (_currentMissed) {
        _recovered++;
        if (_retried.add(exercise)) _queue.addLast(exercise);
      } else {
        _firstTry++;
      }
      _currentMissed = false;
      _eliminated.clear();
      return true;
    }
    mistakes++;
    _currentMissed = true;
    _eliminated.add(choice);
    return false;
  }

  Exercise _build(ExerciseKind kind, Letter target, List<Letter> known) {
    final wanted = maxOptions - 1;
    final distractors = [
      ...known.where((l) => l != target).toList()..shuffle(_random),
    ];
    if (distractors.length < wanted) {
      distractors.addAll([...unseen]..shuffle(_random));
    }
    final options = [target, ...distractors.take(wanted)]..shuffle(_random);
    return Exercise(kind: kind, target: target, options: options);
  }
}
