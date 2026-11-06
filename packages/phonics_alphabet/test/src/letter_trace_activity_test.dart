import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phonics_alphabet/src/letter_trace_activity.dart';
import 'package:phonics_alphabet/src/trace/glyph_mask.dart';

import '../support/letters.dart';

final lMask = GlyphMask.fromRows([
  '..............',
  '.###..........',
  '.###..........',
  '.###..........',
  '.###..........',
  '.###..........',
  '.###..........',
  '.###..........',
  '.###..........',
  '.###..........',
  '.############.',
  '.############.',
  '.############.',
  '..............',
]);

final loaded = <String>[];

Future<GlyphMask> fakeLoader(String glyph) async {
  loaded.add(glyph);
  return lMask;
}

Future<TestHost> pumpTrace(WidgetTester tester) async {
  loaded.clear();
  final host = await pumpActivity(
    tester,
    LetterTraceActivity(letterOf('s'), maskLoader: fakeLoader),
  );
  await tester.pump();
  return host;
}

Future<void> drawL(WidgetTester tester) async {
  final box = tester.getRect(find.byKey(const Key('trace-canvas')));
  Offset at(double x, double y) =>
      box.topLeft + Offset(box.width * x, box.height * y);
  final g = await tester.startGesture(at(0.18, 0.10));
  for (final p in [
    at(0.18, 0.3),
    at(0.18, 0.55),
    at(0.18, 0.80),
    at(0.45, 0.80),
    at(0.80, 0.80),
  ]) {
    await g.moveTo(p);
  }
  await g.up();
  await tester.pump();
}

void main() {
  testWidgets('starts with the big letter and offers Skip', (tester) async {
    await pumpTrace(tester);
    expect(find.text('Trace the big letter'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(loaded, ['S']);
  });

  testWidgets('Clear is only available once something is drawn', (
    tester,
  ) async {
    await pumpTrace(tester);
    final clear = find.widgetWithText(OutlinedButton, 'Clear');
    expect(tester.widget<OutlinedButton>(clear).onPressed, isNull);

    final box = tester.getRect(find.byKey(const Key('trace-canvas')));
    final g = await tester.startGesture(box.center);
    await g.moveBy(const Offset(40, 0));
    await g.moveBy(const Offset(40, 0));
    await g.up();
    await tester.pump();
    expect(tester.widget<OutlinedButton>(clear).onPressed, isNotNull);

    await tester.tap(clear);
    await tester.pump();
    expect(tester.widget<OutlinedButton>(clear).onPressed, isNull);
  });

  testWidgets('tracing the big letter then the small one earns 10 XP', (
    tester,
  ) async {
    final host = await pumpTrace(tester);

    await drawL(tester);
    expect(find.text('Great! Next'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);
    await tester.tap(find.text('Great! Next'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Trace the small letter'), findsOneWidget);
    expect(loaded, ['S', 's']);
    expect(host.results, isEmpty);

    await drawL(tester);
    await tester.tap(find.text('Great! Continue'));
    expect(host.results.single.xp, 10);
    expect(host.results.single.mistakes, 0);
  });

  testWidgets('skipping both earns nothing but still moves on', (tester) async {
    final host = await pumpTrace(tester);
    await tester.tap(find.text('Skip'));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Skip'));
    expect(host.results.single.xp, 0);
  });

  testWidgets('skipping one and tracing the other earns half', (tester) async {
    final host = await pumpTrace(tester);
    await tester.tap(find.text('Skip'));
    await tester.pump();
    await tester.pump();
    await drawL(tester);
    await tester.tap(find.text('Great! Continue'));
    expect(host.results.single.xp, 5);
  });

  testWidgets('scribbling does not finish the trace', (tester) async {
    await pumpTrace(tester);
    final box = tester.getRect(find.byKey(const Key('trace-canvas')));
    for (var i = 0; i < 12; i++) {
      final y = box.top + box.height * (0.04 + i * 0.08);
      final g = await tester.startGesture(Offset(box.left + 4, y));
      await g.moveTo(Offset(box.center.dx, y));
      await g.moveTo(Offset(box.right - 4, y));
      await g.up();
    }
    await tester.pump();
    expect(find.textContaining('Great!'), findsNothing);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('is described for screen readers, who can Skip', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpTrace(tester);
    expect(
      find.bySemanticsLabel(RegExp('Drawing area. Trace the big letter S')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Skip'), findsOneWidget);
    handle.dispose();
  });
}
