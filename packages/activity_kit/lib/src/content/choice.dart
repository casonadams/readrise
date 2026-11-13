/// One answer a learner can pick.
sealed class Choice {
  const Choice(this.text);

  final String text;
}

/// The right answer.
final class Right extends Choice {
  const Right(super.text);
}

/// A wrong answer, with what the learner is told after picking it: why it is
/// wrong, or for a prediction, a word about the idea behind it.
final class Wrong extends Choice {
  const Wrong(super.text, this.feedback);

  final String feedback;
}

/// Where the one [Right] choice is.
int rightIndex(List<Choice> choices) => choices.indexWhere((c) => c is Right);

/// Throws unless exactly one of [choices] is [Right]; [where] names them.
void checkOneRight(List<Choice> choices, String where) {
  final rights = choices.whereType<Right>().length;
  if (rights != 1) {
    throw ArgumentError('$where: needs exactly one Right choice, has $rights');
  }
}

final _positional = RegExp(
  r'\b(all|both|none|neither) of (the|these)\b',
  caseSensitive: false,
);

/// Throws if a choice in [choices] points at the others by position ("all
/// of the above"), which shuffling would break; [where] names them.
void checkNoPositionalText(List<Choice> choices, String where) {
  for (final c in choices) {
    if (_positional.hasMatch(c.text)) {
      throw ArgumentError(
        '$where: "${c.text}" points at other choices, but choices are '
        'shuffled; mark the question ordered or reword it',
      );
    }
  }
}
