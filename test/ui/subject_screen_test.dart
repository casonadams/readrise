import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_plugins.dart';
import '../support/pump_app.dart';

Future<void> openReading(WidgetTester tester) async {
  await tester.tap(find.text('Reading'));
  await tester.pumpAndSettle();
}

void main() {
  final registry = buildSubjectRegistry();

  testWidgets('shows only this subject, with unit banners', (tester) async {
    await pumpApp(tester, registry);
    await openReading(tester);

    expect(find.text('Course r1'), findsOneWidget);
    expect(find.text('Course r2'), findsOneWidget);
    expect(find.text('Course s1'), findsNothing);
  });

  testWidgets('marks the next lesson START and locks the rest', (tester) async {
    await pumpApp(tester, registry);
    await openReading(tester);

    expect(find.text('START'), findsOneWidget);
    expect(find.text('La'), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded), findsWidgets);
  });

  testWidgets('finished lessons show their stars', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester, registry, progress: finished(registry, ['r1/a']));
    await openReading(tester);

    expect(find.bySemanticsLabel('La, 3 of 3 stars'), findsOneWidget);
    expect(find.bySemanticsLabel('Lb, start here'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('tapping a locked lesson explains what unlocks it', (
    tester,
  ) async {
    await pumpApp(tester, registry);
    await openReading(tester);

    await tester.tap(find.byIcon(Icons.lock_rounded).first);
    await tester.pump();

    expect(find.text('Finish La first.'), findsOneWidget);
  });

  testWidgets('a locked unit names the course that unlocks it', (tester) async {
    await pumpApp(tester, registry);
    await openReading(tester);

    expect(find.text('Finish Course r1 first'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.lock_rounded).last);
    await tester.pump();
    expect(find.text('Finish Course r1 to unlock this unit.'), findsOneWidget);
  });

  testWidgets('tapping the START lesson opens it', (tester) async {
    await pumpApp(tester, registry);
    await openReading(tester);

    await tester.tap(find.text('La'));
    await tester.pumpAndSettle();

    expect(find.text('finish a'), findsOneWidget);
  });

  testWidgets('a finished lesson can be replayed', (tester) async {
    await pumpApp(tester, registry, progress: finished(registry, ['r1/a']));
    await openReading(tester);

    await tester.tap(find.text('La'));
    await tester.pumpAndSettle();

    expect(find.text('finish a'), findsOneWidget);
  });
}
