import 'package:activity_kit/activity_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_matter/src/balloon_experiment.dart';
import 'package:science_matter/src/heat_experiments.dart';
import 'package:science_matter/src/zoom_experiment.dart';

/// Shows [experiment] and returns how many times it reported a result.
Future<List<int>> pumpExperiment(
  WidgetTester tester,
  Experiment experiment, {
  bool active = true,
}) async {
  final observed = <int>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 520,
          child: Builder(
            builder: (context) =>
                experiment(context, active, () => observed.add(1)),
          ),
        ),
      ),
    ),
  );
  return observed;
}

Future<void> slideToEnd(WidgetTester tester) async {
  await tester.drag(find.byType(Slider), const Offset(600, 0));
  await tester.pump();
}

void main() {
  testWidgets('balloon: four pumps fill it and report once', (tester) async {
    final observed = await pumpExperiment(tester, balloonExperiment);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Pump'));
      await tester.pump();
    }
    await tester.pump(const Duration(seconds: 2));
    expect(observed, isEmpty);

    await tester.tap(find.text('Pump'));
    await tester.pump(const Duration(seconds: 2));
    expect(observed, hasLength(1));
    expect(find.text('Has mass'), findsOneWidget);
  });

  testWidgets('balloon: the pump is off until the experiment is active', (
    tester,
  ) async {
    await pumpExperiment(tester, balloonExperiment, active: false);
    final pump = tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text('Pump'),
        matching: find.bySubtype<ButtonStyleButton>(),
      ),
    );
    expect(pump.onPressed, isNull);
  });

  for (final (name, experiment) in [
    ('zoom', zoomExperiment),
    ('heat a gas', heatGasExperiment),
    ('stove', stoveExperiment),
  ]) {
    testWidgets('$name: sliding to the end reports once', (tester) async {
      final observed = await pumpExperiment(tester, experiment);
      expect(observed, isEmpty);
      await slideToEnd(tester);
      await slideToEnd(tester);
      expect(observed, hasLength(1));
    });

    testWidgets('$name: the slider is off until active', (tester) async {
      final observed = await pumpExperiment(tester, experiment, active: false);
      await slideToEnd(tester);
      expect(observed, isEmpty);
    });
  }
}
