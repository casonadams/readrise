import 'package:activity_kit/activity_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readrise_testing/readrise_testing.dart';

const _slider = ControlledExperiment<double>(
  control: SliderControl(
    label: 'Heat',
    low: Icons.ac_unit_rounded,
    high: Icons.local_fire_department_rounded,
  ),
  observed: _atTop,
  view: _PercentText.new,
);

const _pump = ControlledExperiment<int>(
  control: TapControl(label: 'Pump', icon: Icons.air_rounded, presses: 2),
  observed: _twoPresses,
  view: _ValueText.new,
  settle: Duration(seconds: 1),
);

bool _atTop(double value) => value >= 0.98;

bool _twoPresses(int presses) => presses >= 2;

class _PercentText extends StatelessWidget {
  const _PercentText(this.value);

  final double value;

  @override
  Widget build(BuildContext context) => Text('${(value * 100).round()}%');
}

class _ValueText extends StatelessWidget {
  const _ValueText(this.value);

  final int value;

  @override
  Widget build(BuildContext context) => Text('value $value');
}

void main() {
  experimentContract('slider', _slider, observe: slideToEnd);
  experimentContract('tap', _pump, observe: tapTimes('Pump', 2));

  testWidgets('the control does nothing until the experiment is active', (
    tester,
  ) async {
    await pumpExperiment(tester, _slider, active: false);
    await slideToEnd(tester);
    expect(find.text('0%'), findsOneWidget);
  });

  testWidgets('reports once, however often the result is reached', (
    tester,
  ) async {
    final reports = await pumpExperiment(tester, _slider);
    await slideToEnd(tester);
    await tester.drag(find.byType(Slider), const Offset(-600, 0));
    await tester.pump();
    await slideToEnd(tester);
    expect(find.text('100%'), findsOneWidget);
    expect(reports, hasLength(1));
  });

  testWidgets('waits for the settle time before reporting', (tester) async {
    final reports = await pumpExperiment(tester, _pump);
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
    final reports = await pumpExperiment(tester, _pump);
    await tester.tap(find.text('Pump'));
    await tester.pump();
    await tester.tap(find.text('Pump'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
    expect(reports, isEmpty);
  });

  testWidgets('a tap control steps aside after its last press', (tester) async {
    await pumpExperiment(tester, _pump);
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
