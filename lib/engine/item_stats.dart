import 'dart:math';

import 'package:readrise_plugin_api/readrise_plugin_api.dart';

/// Where an item's stats are stored.
typedef ItemKey = ({CourseId course, ItemId item});

String encodeItemKey(ItemKey key) => '${key.course.value}/${key.item.value}';

ItemKey decodeItemKey(String text) => switch (text.split('/')) {
  [final course, final item] => (course: CourseId(course), item: ItemId(item)),
  _ => throw FormatException('not a "course/item" key', text),
};

/// How a learner has done on one item. [box] is its Leitner box: a
/// first-try answer moves it up one, any other answer sends it back to 0,
/// so the lowest boxes hold what the learner finds hard.
class ItemStats {
  const ItemStats({
    required this.seen,
    required this.firstTries,
    required this.box,
    required this.lastSeen,
  });

  factory ItemStats.fromJson(Map<String, dynamic> json) => ItemStats(
    seen: json['seen'] as int,
    firstTries: json['firstTries'] as int,
    box: json['box'] as int,
    lastSeen: DateTime.parse(json['lastSeen'] as String),
  );

  /// The stats of an item after it is answered at [now]; [before] is null
  /// for its first answer.
  factory ItemStats.answered(
    ItemStats? before, {
    required bool firstTry,
    required DateTime now,
  }) => ItemStats(
    seen: (before?.seen ?? 0) + 1,
    firstTries: (before?.firstTries ?? 0) + (firstTry ? 1 : 0),
    box: firstTry ? min(topBox, (before?.box ?? 0) + 1) : 0,
    lastSeen: now,
  );

  static const topBox = 4;

  final int seen;
  final int firstTries;
  final int box;
  final DateTime lastSeen;

  Map<String, dynamic> toJson() => {
    'seen': seen,
    'firstTries': firstTries,
    'box': box,
    'lastSeen': lastSeen.toIso8601String(),
  };
}
