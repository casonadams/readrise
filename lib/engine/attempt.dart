import 'dart:math';

import 'package:readrise_plugin_api/readrise_plugin_api.dart';

import 'item_stats.dart';
import 'review.dart';

/// The activities for one attempt at [lesson], in the lesson's order. Each
/// gets its own random from [seed], so one activity's choices never change
/// another's arrangement. A [Review] reviews the items hardest for the
/// learner by [stats]; a [Randomizable] is shuffled.
List<ActivityPlugin> attemptActivities(
  LessonPlugin lesson, {
  required int seed,
  required Map<ItemId, ItemStats> stats,
}) {
  final seeds = Random(seed);
  return [
    for (final authored in lesson.activities)
      _arrange(authored, Random(seeds.nextInt(1 << 32)), stats),
  ];
}

ActivityPlugin _arrange(
  ActivityPlugin activity,
  Random random,
  Map<ItemId, ItemStats> stats,
) {
  var arranged = activity;
  if (arranged case final Review review) {
    final items = pickForReview(
      review.reviewable,
      review.reviewSize,
      stats,
      random,
    );
    if (items != null) arranged = review.reviewing(items);
  }
  if (arranged case final Randomizable varies) {
    arranged = varies.shuffled(random);
  }
  return arranged;
}
