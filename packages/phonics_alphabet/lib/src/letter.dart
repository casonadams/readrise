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
