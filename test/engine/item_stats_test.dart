import 'package:flutter_test/flutter_test.dart';
import 'package:readrise/engine/item_stats.dart';

void main() {
  final now = DateTime(2026, 3, 8, 10);
  ItemStats inBox(int box) =>
      ItemStats(seen: 3, firstTries: 1, box: box, lastSeen: DateTime(2026));

  final cases = <String, (ItemStats?, bool, int)>{
    'a first answer, right first time, goes to box 1': (null, true, 1),
    'a first answer that needed help stays in box 0': (null, false, 0),
    'right first time moves up one box': (inBox(2), true, 3),
    'the top box is as high as it goes': (inBox(ItemStats.topBox), true, 4),
    'any miss sends it back to box 0': (inBox(3), false, 0),
  };
  cases.forEach((name, c) {
    final (before, firstTry, box) = c;
    test(name, () {
      final after = ItemStats.answered(before, firstTry: firstTry, now: now);
      expect(after.box, box);
      expect(after.seen, (before?.seen ?? 0) + 1);
      expect(after.firstTries, (before?.firstTries ?? 0) + (firstTry ? 1 : 0));
      expect(after.lastSeen, now);
    });
  });
}
