import 'package:activity_kit/activity_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/recording_host.dart';

const activity = SortActivity(
  prompt: 'Sort them',
  bins: ['Hot', 'Cold'],
  items: [SortItem('Fire', bin: 0), SortItem('Ice', bin: 1)],
);

void main() {
  testWidgets('tapping the right bins places items and finishes', (
    tester,
  ) async {
    final host = await pumpActivity(tester, activity);

    expect(find.text('Fire'), findsOneWidget);
    await tester.tap(find.text('Hot'));
    await tester.pump();
    expect(find.widgetWithText(Chip, 'Fire'), findsOneWidget);
    expect(find.text('Ice'), findsOneWidget);

    await tester.tap(find.text('Cold'));
    await tester.pump();
    expect(find.text('All sorted!'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    expect(host.results.single.xp, 20);
    expect(host.results.single.mistakes, 0);
  });

  testWidgets('a wrong bin keeps the item, counts a mistake, halves credit', (
    tester,
  ) async {
    final host = await pumpActivity(tester, activity);

    await tester.tap(find.text('Cold'));
    await tester.pump();
    expect(find.widgetWithText(Chip, 'Fire'), findsNothing);
    expect(find.text('Fire'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(find.text('Hot'));
    await tester.pump();
    await tester.tap(find.text('Cold'));
    await tester.pump();
    await tester.tap(find.text('Continue'));

    expect(host.results.single.mistakes, 1);
    expect(host.results.single.xp, 15);
  });

  testWidgets('dragging an item onto its bin places it', (tester) async {
    await pumpActivity(tester, activity);

    await tester.drag(
      find.text('Fire'),
      tester.getCenter(find.text('Hot')) -
          tester.getCenter(find.text('Fire')) +
          const Offset(0, 40),
    );
    await tester.pump();

    expect(find.widgetWithText(Chip, 'Fire'), findsOneWidget);
  });
}
