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
}

class Skill {
  const Skill({required this.id, required this.letters});

  final String id;
  final List<Letter> letters;

  String get title => letters.map((l) => l.upper + l.char).join(' ');
}

class Curriculum {
  const Curriculum(this.skills);

  final List<Skill> skills;

  Skill byId(String id) => skills.firstWhere((s) => s.id == id);

  int indexOf(Skill skill) => skills.indexOf(skill);

  /// Letters taught up to and including [skill]; distractor pool for lessons.
  List<Letter> lettersThrough(Skill skill) => [
    for (final s in skills.take(indexOf(skill) + 1)) ...s.letters,
  ];
}

const _s = Letter(char: 's', sound: 'sss', word: 'sun', emoji: '\u2600\uFE0F');
const _a = Letter(char: 'a', sound: 'aah', word: 'apple', emoji: '\u{1F34E}');
const _t = Letter(char: 't', sound: 'tuh', word: 'tiger', emoji: '\u{1F42F}');
const _p = Letter(char: 'p', sound: 'puh', word: 'pig', emoji: '\u{1F437}');
const _i = Letter(char: 'i', sound: 'ih', word: 'igloo', emoji: '\u{1F9CA}');
const _n = Letter(char: 'n', sound: 'nnn', word: 'nest', emoji: '\u{1FAB9}');

/// Phonics order SATPIN: early letters combine into many simple words.
const curriculum = Curriculum([
  Skill(id: 'sa', letters: [_s, _a]),
  Skill(id: 'tp', letters: [_t, _p]),
  Skill(id: 'in', letters: [_i, _n]),
]);
