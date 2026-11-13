import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

import 'activity_header.dart';
import 'choice_quiz_activity.dart';
import 'content/question.dart';

/// A warm-up on earlier lessons. It asks its own [questions] until the
/// learner has answered enough of the [pool] (usually the earlier lessons'
/// check questions); from then on the engine has it ask the pool questions
/// the learner finds hardest.
class WarmUpQuiz
    implements ActivityPlugin, Validated, Randomizable, HasItems, Review {
  const WarmUpQuiz({required this.questions, required this.pool});

  final List<ChoiceQuestion> questions;
  final List<ChoiceQuestion> pool;

  ChoiceQuizActivity get _authored =>
      ChoiceQuizActivity(kind: ActivityKind.warmUp, questions: questions);

  @override
  Iterable<ItemId> get items => _authored.items;

  @override
  Iterable<ItemId> get reviewable => pool.map((q) => q.id);

  @override
  int get reviewSize => questions.length;

  @override
  ChoiceQuizActivity reviewing(List<ItemId> items) => ChoiceQuizActivity(
    kind: ActivityKind.warmUp,
    questions: [for (final id in items) pool.firstWhere((q) => q.id == id)],
  );

  @override
  ChoiceQuizActivity shuffled(Random random) => _authored.shuffled(random);

  @override
  void validate() => _authored.validate();

  @override
  Widget build(BuildContext context, ActivityHost host) =>
      _authored.build(context, host);
}
