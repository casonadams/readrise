import 'dart:math';

import 'package:readrise_plugin_api/readrise_plugin_api.dart';

import 'item_stats.dart';

/// Picks [size] of the [pool] items to review: the hardest for the learner
/// first (lowest Leitner box), then those seen longest ago, with ties broken
/// by [random]. Only answered items count; returns null when fewer than
/// [size] have been answered.
List<ItemId>? pickForReview(
  Iterable<ItemId> pool,
  int size,
  Map<ItemId, ItemStats> stats,
  Random random,
) {
  final answered = [
    for (final item in pool)
      if (stats.containsKey(item)) item,
  ]..shuffle(random);
  if (answered.length < size) return null;
  answered.sort((a, b) {
    final (sa, sb) = (stats[a]!, stats[b]!);
    final byBox = sa.box.compareTo(sb.box);
    return byBox != 0 ? byBox : sa.lastSeen.compareTo(sb.lastSeen);
  });
  return answered.take(size).toList();
}
