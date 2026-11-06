import 'package:activity_kit/src/shake.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget app(int trigger, {bool reduceMotion = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Center(
      child: Shake(
        trigger: trigger,
        child: const SizedBox(key: Key('box'), width: 40, height: 40),
      ),
    ),
  ),
);

double boxX(WidgetTester tester) =>
    tester.getTopLeft(find.byKey(const Key('box'))).dx;

void main() {
  testWidgets('stays still until triggered', (tester) async {
    await tester.pumpWidget(app(0));
    final rest = boxX(tester);
    await tester.pump(const Duration(milliseconds: 100));
    expect(boxX(tester), rest);
  });

  testWidgets('moves sideways when triggered, then settles back', (
    tester,
  ) async {
    await tester.pumpWidget(app(0));
    final rest = boxX(tester);

    await tester.pumpWidget(app(1));
    await tester.pump(const Duration(milliseconds: 40));
    expect(boxX(tester), isNot(closeTo(rest, 0.5)));

    await tester.pump(const Duration(milliseconds: 600));
    expect(boxX(tester), closeTo(rest, 0.01));
  });

  testWidgets('does not move when the user reduced motion', (tester) async {
    await tester.pumpWidget(app(0, reduceMotion: true));
    final rest = boxX(tester);
    await tester.pumpWidget(app(1, reduceMotion: true));
    await tester.pump(const Duration(milliseconds: 40));
    expect(boxX(tester), rest);
  });
}
