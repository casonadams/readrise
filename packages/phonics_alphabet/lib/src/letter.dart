/// Font for letter shapes: Andika (SIL OFL) draws the single-story "a" and
/// "g" that children are taught to write.
const letterFontFamily = 'Andika';
const letterFontPackage = 'phonics_alphabet';

class PictureWord {
  const PictureWord(this.word, this.emoji);

  final String word;
  final String emoji;
}

class Letter {
  const Letter({
    required this.char,
    required this.word,
    required this.emoji,
    this.more = const [],
  });

  final String char;

  /// The main picture word. It starts with [char] unless no common word does
  /// (see [startsWord]).
  final String word;
  final String emoji;

  /// More pictures that start with the same sound, for games that need
  /// several (Feed the Monster).
  final List<PictureWord> more;

  String get upper => char.toUpperCase();
  String get display => '$upper$char';

  List<PictureWord> get pictures => [PictureWord(word, emoji), ...more];

  /// Whether [word] begins with this letter. Letters like x teach with a word
  /// that ends in the letter ("fox"), so "which letter does it start with?"
  /// would be a wrong question for them.
  bool get startsWord => word.startsWith(char);

  /// Index of this letter within [word] to highlight.
  int get highlightIndex => startsWord ? 0 : word.lastIndexOf(char);

  /// The letter children most often mirror this one with, if any.
  String? get mirrorChar => _mirrors[char];

  /// Letters whose words start with the same sound (c/k/q), so a picture of
  /// one is a bad "wrong answer" for another.
  Set<String> get soundTwins => _twins[char] ?? const {};

  static const _mirrors = {'b': 'd', 'd': 'b', 'p': 'q', 'q': 'p'};
  static const _twins = {
    'c': {'k', 'q'},
    'k': {'c', 'q'},
    'q': {'c', 'k'},
  };
}
