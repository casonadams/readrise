import 'dart:collection';
import 'dart:math';

import 'letter.dart';

enum ExerciseKind {
  /// Hear a letter, pick it.
  soundToLetter,

  /// See a picture and hear its word, pick the letter it starts with.
  pictureToLetter,
}

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

class QuizSession {
  QuizSession._(this._random, this._queue, {required this.maxOptions});

  /// A lesson quiz for a newly taught [letter]: it is asked three times and the
  /// two most recently learned letters are reviewed. While [letter] is new its
  /// mirror twin (b/d, p/q) is kept out of the choices.
  factory QuizSession.lesson({
    required Letter letter,
    List<Letter> learned = const [],
    List<Letter> unseen = const [],
    Random? random,
  }) {
    final r = random ?? Random();
    final known = [...learned, letter];
    final targets = [letter, letter, ...learned.reversed.take(2), letter];
    return QuizSession._(r, Queue(), maxOptions: _optionCount(known.length))
      .._fill(
        [
          for (var i = 0; i < targets.length; i++)
            (targets[i], ExerciseKind.values[i % 2]),
        ],
        known: known,
        unseen: unseen,
        avoid: {letter.mirrorChar},
      );
  }

  /// A review quiz over [letters]: each is heard once and seen once, in random
  /// order. [known] are all letters taught so far (the wrong-answer pool).
  factory QuizSession.review({
    required List<Letter> letters,
    required List<Letter> known,
    Random? random,
  }) {
    final r = random ?? Random();
    final plan = [
      for (final l in letters)
        for (final k in ExerciseKind.values) (l, k),
    ]..shuffle(r);
    return QuizSession._(r, Queue(), maxOptions: _optionCount(known.length))
      .._fill(plan, known: known, unseen: const [], avoid: const {});
  }

  /// Three choices at first, four once enough letters are known.
  static int _optionCount(int known) => known >= 8 ? 4 : 3;

  final int maxOptions;
  final Random _random;
  final Queue<Exercise> _queue;
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

  bool isEliminated(Letter letter) => _eliminated.contains(letter);

  /// Options still selectable; wrong picks are crossed out so the choice
  /// narrows while every option keeps its place on screen.
  List<Letter> get visibleOptions => [
    for (final o in current.options)
      if (!_eliminated.contains(o)) o,
  ];

  /// Returns true when [choice] is correct and the lesson advanced.
  bool answer(Letter choice) {
    final exercise = current;
    if (choice == exercise.target) {
      _queue.removeFirst();
      if (_retried.contains(exercise)) {
        // Practice round after a miss: no credit, so missing on purpose
        // never pays.
      } else if (_currentMissed) {
        _recovered++;
        _retried.add(exercise);
        _queue.addLast(exercise);
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

  void _fill(
    List<(Letter, ExerciseKind)> plan, {
    required List<Letter> known,
    required List<Letter> unseen,
    required Set<String?> avoid,
  }) {
    for (final (letter, kind) in plan) {
      _queue.add(
        _build(
          kind == ExerciseKind.pictureToLetter && !letter.startsWord
              ? ExerciseKind.soundToLetter
              : kind,
          letter,
          known,
          unseen,
          avoid,
        ),
      );
    }
  }

  Exercise _build(
    ExerciseKind kind,
    Letter target,
    List<Letter> known,
    List<Letter> unseen,
    Set<String?> avoid,
  ) {
    final wanted = maxOptions - 1;
    final distractors = [
      ...known.where((l) => l != target).toList()..shuffle(_random),
    ];
    if (distractors.length < wanted) {
      distractors.addAll([...unseen]..shuffle(_random));
    }
    final preferred = [
      for (final l in distractors)
        if (!avoid.contains(l.char)) l,
    ];
    final pool = preferred.length >= wanted ? preferred : distractors;
    final options = [target, ...pool.take(wanted)]..shuffle(_random);
    return Exercise(kind: kind, target: target, options: options);
  }
}
