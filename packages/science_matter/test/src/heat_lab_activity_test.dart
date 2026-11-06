import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_matter/src/heat_lab_activity.dart';
import 'package:science_matter/src/matter_state.dart';

import '../support/recording_host.dart';

const activity = HeatLabActivity(
  goals: [
    HeatGoal(prompt: 'Melt it', target: MatterState.liquid),
    HeatGoal(prompt: 'Boil it', target: MatterState.gas),
    HeatGoal(prompt: 'Freeze it', target: MatterState.solid),
  ],
);

Future<void> setTemperature(WidgetTester tester, double celsius) async {
  tester.widget<Slider>(find.byType(Slider)).onChanged!(celsius);
  await tester.pump();
}

void main() {
  testWidgets('starts frozen at -20, showing the first goal', (tester) async {
    await pumpActivity(tester, activity);
    expect(find.text('Goal 1 of 3'), findsOneWidget);
    expect(find.text('Melt it'), findsOneWidget);
    expect(find.textContaining('-20\u00B0C'), findsOneWidget);
    expect(find.textContaining('Solid'), findsOneWidget);
    expect(find.textContaining('Next goal'), findsNothing);
  });

  testWidgets('the wrong state does not unlock the next goal', (tester) async {
    await pumpActivity(tester, activity);
    await setTemperature(tester, 120);
    expect(find.textContaining('Gas'), findsOneWidget);
    expect(find.textContaining('Next goal'), findsNothing);
  });

  testWidgets('melt, boil, then freeze completes with full XP', (tester) async {
    final host = await pumpActivity(tester, activity);

    await setTemperature(tester, 25);
    expect(find.textContaining('Liquid'), findsOneWidget);
    await tester.tap(find.textContaining('Next goal'));
    await tester.pump();

    expect(find.text('Goal 2 of 3'), findsOneWidget);
    expect(find.textContaining('Next goal'), findsNothing);
    await setTemperature(tester, 100);
    await tester.tap(find.textContaining('Next goal'));
    await tester.pump();

    expect(find.text('Freeze it'), findsOneWidget);
    expect(host.results, isEmpty);
    await setTemperature(tester, -5);
    await tester.tap(find.text('Finish'));

    expect(host.results.single.xp, 20);
    expect(host.results.single.mistakes, 0);
  });
}
