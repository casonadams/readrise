import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:phonics_alphabet/src/trace/glyph_mask.dart';
import 'package:phonics_alphabet/src/trace/trace_checker.dart';

import '../../support/andika.dart';

/// Every glyph the trace screen can show: 26 capitals and 26 small letters.
final glyphs = [
  for (var c = 0; c < 26; c++) ...[
    String.fromCharCode(65 + c),
    String.fromCharCode(97 + c),
  ],
];

void main() {
  late Map<String, GlyphMask> masks;

  setUpAll(() async {
    await loadAndika();
    masks = {};
  });

  Future<GlyphMask> maskFor(WidgetTester tester, String glyph) async =>
      masks[glyph] ??= (await tester.runAsync(() => GlyphMask.render(glyph)))!;

  testWidgets('every letter has a sensible amount of ink inside the box', (
    tester,
  ) async {
    for (final g in glyphs) {
      final mask = await maskFor(tester, g);
      final share = mask.inkCount / (mask.size * mask.size);
      expect(share, inInclusiveRange(0.02, 0.45), reason: g);
      // Nothing touches the border, so strokes near the edge are not needed.
      for (var i = 0; i < mask.size; i++) {
        expect(mask.at(i, 0) || mask.at(i, mask.size - 1), isFalse, reason: g);
        expect(mask.at(0, i) || mask.at(mask.size - 1, i), isFalse, reason: g);
      }
    }
  });

  testWidgets('touching every part of any letter completes its trace', (
    tester,
  ) async {
    for (final g in glyphs) {
      final mask = await maskFor(tester, g);
      final checker = TraceChecker(mask);
      for (var y = 0; y < mask.size; y += 2) {
        for (var x = 0; x < mask.size; x += 2) {
          if (mask.at(x, y)) {
            checker.startStroke(
              Offset((x + .5) / mask.size, (y + .5) / mask.size),
            );
            checker.endStroke();
          }
        }
      }
      expect(checker.isComplete, isTrue, reason: g);
    }
  });

  testWidgets('scribbling across the whole box never completes any letter', (
    tester,
  ) async {
    for (final g in glyphs) {
      final checker = TraceChecker(await maskFor(tester, g));
      for (var y = 0.03; y < 1; y += 0.04) {
        checker.startStroke(Offset(0.03, y));
        checker.extendStroke(Offset(0.97, y));
        checker.endStroke();
      }
      expect(checker.isComplete, isFalse, reason: g);
    }
  });

  testWidgets('a ring drawn round the o completes; a small circle does not', (
    tester,
  ) async {
    final mask = await maskFor(tester, 'o');
    var cx = 0.0, cy = 0.0, n = 0;
    for (var y = 0; y < mask.size; y++) {
      for (var x = 0; x < mask.size; x++) {
        if (mask.at(x, y)) {
          cx += x;
          cy += y;
          n++;
        }
      }
    }
    cx /= n;
    cy /= n;
    var radius = 0.0;
    for (var y = 0; y < mask.size; y++) {
      for (var x = 0; x < mask.size; x++) {
        if (mask.at(x, y)) radius += sqrt(pow(x - cx, 2) + pow(y - cy, 2));
      }
    }
    radius /= n;

    TraceChecker circle(double r) {
      final c = TraceChecker(mask);
      Offset at(double a) =>
          Offset((cx + r * cos(a)) / mask.size, (cy + r * sin(a)) / mask.size);
      c.startStroke(at(0));
      for (var a = 0.0; a <= 2 * pi + 0.1; a += 0.15) {
        c.extendStroke(at(a));
      }
      return c;
    }

    expect(circle(radius).isComplete, isTrue);
    expect(circle(radius * 0.4).isComplete, isFalse);
    expect(circle(radius * 1.8).isComplete, isFalse);
  });
}
