import 'dart:collection';
import 'dart:math';

import 'letter.dart';

class Food {
  const Food(this.picture, {required this.edible});

  final PictureWord picture;

  /// Whether the picture starts with the monster's letter.
  final bool edible;
}

/// Feed the Monster: a monster wants things that start with [letter]; the
/// learner feeds it the right pictures and throws the rest away.
class MonsterSession {
  MonsterSession({
    required this.letter,
    List<Letter> learned = const [],
    List<Letter> unseen = const [],
    this.total = 6,
    required Random random,
  }) {
    assert(letter.startsWord, 'only letters that start their word can be fed');
    final edible = ([...letter.pictures]..shuffle(random)).take(3).toList();
    final blocked = {letter.char, letter.mirrorChar, ...letter.soundTwins};
    final candidates = [
      for (final pool in [learned, unseen])
        ([
          for (final l in pool)
            if (!blocked.contains(l.char) && l.startsWord) l,
        ]..shuffle(random)),
    ];
    final others = <PictureWord>[];
    for (final pool in candidates) {
      for (final l in pool) {
        if (others.length >= total - edible.length) break;
        others.add(([...l.pictures]..shuffle(random)).first);
      }
    }
    final foods = [
      for (final p in edible) Food(p, edible: true),
      for (final p in others) Food(p, edible: false),
    ]..shuffle(random);
    _queue.addAll(foods);
  }

  final Letter letter;
  final int total;
  final Queue<Food> _queue = Queue();
  final Set<Food> _retried = {};
  bool _currentMissed = false;
  int _firstTry = 0;
  int _recovered = 0;
  int mistakes = 0;

  bool get isComplete => _queue.isEmpty;
  Food get current => _queue.first;
  int get completed => _firstTry + _recovered;
  double get progress => completed / (completed + _queue.length);
  int get xp => _firstTry * 5 + _recovered * 2;

  /// [feed] true means "give it to the monster". Returns whether that was
  /// right; a wrong answer keeps the food in play and brings it back later.
  bool answer({required bool feed}) {
    final food = current;
    if (feed == food.edible) {
      _queue.removeFirst();
      if (_retried.contains(food)) {
        // Practice round after a miss: no credit, so missing on purpose
        // never pays.
      } else if (_currentMissed) {
        _recovered++;
        _retried.add(food);
        _queue.addLast(food);
      } else {
        _firstTry++;
      }
      _currentMissed = false;
      return true;
    }
    mistakes++;
    _currentMissed = true;
    return false;
  }
}
