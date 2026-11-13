import 'package:activity_kit/activity_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// An experiment that shows an empty box and never reports, for tests of
/// activities that hold one.
class StandInExperiment implements Experiment {
  const StandInExperiment();

  @override
  Widget build(
    BuildContext context, {
    required bool active,
    required VoidCallback onObserved,
  }) => const SizedBox.expand();
}

/// What a learner does to an experiment until its result shows.
typedef Observe = Future<void> Function(WidgetTester tester);

/// Shows [experiment] at phone size and returns the list each report of
/// [Experiment]'s `onObserved` adds to.
Future<List<void>> pumpExperiment(
  WidgetTester tester,
  Experiment experiment, {
  bool active = true,
}) async {
  final reports = <void>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 520,
          child: Builder(
            builder: (context) => experiment.build(
              context,
              active: active,
              onObserved: () => reports.add(null),
            ),
          ),
        ),
      ),
    ),
  );
  return reports;
}

/// Drags the experiment's slider to its far end.
Future<void> slideToEnd(WidgetTester tester) async {
  await tester.drag(find.byType(Slider), const Offset(600, 0));
  await tester.pump();
}

/// Taps the control labelled [label] [times] times.
Observe tapTimes(String label, int times) => (tester) async {
  for (var i = 0; i < times; i++) {
    await tester.tap(find.text(label));
    await tester.pump();
  }
};

/// The rules every [Experiment] follows (AGENTS.md, "Scenes and
/// experiments"), as tests: [observe] is what the learner does to see the
/// result.
void experimentContract(
  String name,
  Experiment experiment, {
  required Observe observe,
}) {
  group('$name experiment', () {
    testWidgets('does nothing until it is active', (tester) async {
      final reports = await pumpExperiment(tester, experiment, active: false);
      await observe(tester);
      await tester.pump(const Duration(seconds: 2));
      expect(reports, isEmpty);
    });

    testWidgets('reports once when the result shows', (tester) async {
      final reports = await pumpExperiment(tester, experiment);
      await observe(tester);
      await tester.pump(const Duration(seconds: 2));
      expect(reports, hasLength(1));
    });
  });
}
