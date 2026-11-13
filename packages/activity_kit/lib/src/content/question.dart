import 'package:flutter/widgets.dart';

import 'choice.dart';

/// Wrong picks before a question's hint appears unasked.
const hintAfterMisses = 2;

/// The second tier of a question: after the right answer, the learner picks
/// the reason it is right. A right answer for a wrong reason is the
/// misconception this catches.
class Reason {
  const Reason({required this.choices, this.prompt = 'Why is that?'});

  final String prompt;
  final List<Choice> choices;
}

class ChoiceQuestion {
  const ChoiceQuestion({
    required this.prompt,
    required this.choices,
    required this.explanation,
    this.hint,
    this.reason,
    this.visual,
  });

  final String prompt;
  final List<Choice> choices;

  /// Shown once the question is settled; say why it is right.
  final String explanation;

  /// A nudge toward the answer without giving it away. Offered on request,
  /// and shown on its own after [hintAfterMisses] wrong picks.
  final String? hint;

  /// Asked once the answer is right, before the explanation.
  final Reason? reason;

  final WidgetBuilder? visual;

  /// Throws unless the question and its reason each have one right choice.
  void validate() {
    checkOneRight(choices, prompt);
    if (reason case final reason?) {
      checkOneRight(reason.choices, '$prompt (reason)');
    }
  }
}
