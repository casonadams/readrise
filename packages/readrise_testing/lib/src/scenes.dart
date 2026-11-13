import 'package:activity_kit/activity_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shows [scene] at [step]. Calling again with a new step rebuilds the same
/// widgets, so animations between steps run as they do in the app.
Future<void> pumpScene(
  WidgetTester tester,
  ExplainerScene scene,
  int step, {
  Duration settle = const Duration(seconds: 3),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 500,
          child: Builder(builder: (context) => scene(context, step)),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(settle);
}

/// Product of every [AnimatedOpacity] above the widget showing [text].
double opacityOf(WidgetTester tester, String text) {
  expect(find.text(text), findsWidgets, reason: text);
  return tester
      .widgetList<AnimatedOpacity>(
        find.ancestor(
          of: find.text(text),
          matching: find.byType(AnimatedOpacity),
        ),
      )
      .fold(1.0, (product, w) => product * w.opacity);
}
