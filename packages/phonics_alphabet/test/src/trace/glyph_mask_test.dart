import 'package:flutter_test/flutter_test.dart';
import 'package:phonics_alphabet/src/trace/glyph_mask.dart';

void main() {
  test('fromRows reads # as ink', () {
    final m = GlyphMask.fromRows(['#.', '.#']);
    expect(m.size, 2);
    expect(m.at(0, 0), isTrue);
    expect(m.at(1, 0), isFalse);
    expect(m.inkCount, 2);
  });

  testWidgets('rendering a letter yields ink, centred in the box', (
    tester,
  ) async {
    final mask = (await tester.runAsync(() => GlyphMask.render('S')))!;
    expect(mask.size, 96);
    expect(mask.inkCount, greaterThan(100));
    expect(mask.inkCount, lessThan(96 * 96));

    var minX = 96, maxX = 0;
    for (var y = 0; y < 96; y++) {
      for (var x = 0; x < 96; x++) {
        if (mask.at(x, y)) {
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
        }
      }
    }
    expect((minX + maxX) / 2, closeTo(48, 6));
  });
}
