import 'package:activity_kit/activity_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _slider = ControlledExperiment<double>(
  control: SliderControl(
    label: 'Heat',
    low: Icons.ac_unit_rounded,
    high: Icons.local_fire_department_rounded,
  ),
  observed: _atTop,
  view: _ValueText.new,
);

const _pump = ControlledExperiment<int>(
  control: TapControl(label: 'Pump', icon: Icons.air_rounded, presses: 2),
  observed: _twoPresses,
  view: _ValueText.new,
  settle: Duration(seconds: 1),
);

bool _atTop(double value) => value >= 0.98;

bool _twoPresses(int presses) => presses >= 2;

class _ValueText extends StatelessWidget {
  const _ValueText(this.value);

  final Object value;

  @override
  Widget build(BuildContext context) => Text('value $value');
}

/// Shows [experiment] and returns the list its reports are added to.
Future<List<int>> show(
  WidgetTester tester,
  Experiment experiment, {
  bool active = true,
}) async {
  final reports = <int>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 300,
          child: Builder(
            builder: (context) => experiment.build(
              context,
              active: active,
              onObserved: () => reports.add(1),
            ),
          ),
        ),
      ),
    ),
  );
  return reports;
}

Future<void> slideToEnd(WidgetTester tester) async {
  await tester.drag(find.byType(Slider), const Offset(600, 0));
  await tester.pump();
}

void main() {
  testWidgets('the control does nothing until the experiment is active', (
    tester,
  ) async {
    final reports = await show(tester, _slider, active: false);
    await slideToEnd(tester);
    expect(find.text('value 0.0'), findsOneWidget);
    expect(reports, isEmpty);
  });

  testWidgets('reports once, however often the result is reached', (
    tester,
  ) async {
    final reports = await show(tester, _slider);
    await slideToEnd(tester);
    await tester.drag(find.byType(Slider), const Offset(-600, 0));
    await tester.pump();
    await slideToEnd(tester);
    expect(find.text('value 1.0'), findsOneWidget);
    expect(reports, hasLength(1));
  });

  testWidgets('waits for the settle time before reporting', (tester) async {
    final reports = await show(tester, _pump);
    await tester.tap(find.text('Pump'));
    await tester.pump();
    await tester.tap(find.text('Pump'));
    await tester.pump(const Duration(milliseconds: 900));
    expect(reports, isEmpty);
    await tester.pump(const Duration(milliseconds: 200));
    expect(reports, hasLength(1));
  });

  testWidgets('never reports if it leaves the screen while settling', (
    tester,
  ) async {
    final reports = await show(tester, _pump);
    await tester.tap(find.text('Pump'));
    await tester.pump();
    await tester.tap(find.text('Pump'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
    expect(reports, isEmpty);
  });

  testWidgets('a tap control steps aside after its last press', (tester) async {
    await show(tester, _pump);
    await tester.tap(find.text('Pump'));
    await tester.pump();
    expect(find.text('Pump'), findsOneWidget);
    await tester.tap(find.text('Pump'));
    await tester.pump();
    expect(find.text('Pump'), findsNothing);
    expect(find.text('value 2'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });
}
