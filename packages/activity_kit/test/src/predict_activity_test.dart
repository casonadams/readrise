import 'package:activity_kit/activity_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/recording_host.dart';

/// A stand-in experiment: shows whether it is running and has a button that
/// reports the observation.
class _StandIn implements Experiment {
  const _StandIn();

  @override
  Widget build(
    BuildContext context, {
    required bool active,
    required VoidCallback onObserved,
  }) => Column(
    children: [
      Text(active ? 'running' : 'waiting'),
      TextButton(onPressed: onObserved, child: const Text('observe')),
    ],
  );
}

const _activity = PredictActivity(
  question: 'Will it float?',
  choices: [
    Wrong('Sink', 'Lots of people think heavy-looking things sink.'),
    Right('Float'),
  ],
  tryIt: 'Drop it in',
  experiment: _StandIn(),
  outcome: 'It floats because it is light.',
);

Future<void> predict(WidgetTester tester, String option, String sure) async {
  await tester.tap(find.text(option));
  await tester.pumpAndSettle();
  await tester.tap(find.text(sure));
  await tester.pumpAndSettle();
}

Future<void> observe(WidgetTester tester) async {
  await tester.tap(find.text('observe'));
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the experiment waits for a prediction and a confidence', (
    tester,
  ) async {
    await pumpActivity(tester, _activity);
    expect(find.text('waiting'), findsOneWidget);
    expect(find.text('How sure are you?').hitTestable(), findsNothing);

    await tester.tap(find.text('Sink'));
    await tester.pumpAndSettle();
    expect(find.text('How sure are you?'), findsOneWidget);
    expect(find.text('waiting'), findsOneWidget);

    await tester.tap(find.text('Totally sure'));
    await tester.pumpAndSettle();
    expect(find.text('running'), findsOneWidget);
    expect(find.text('Drop it in'), findsOneWidget);
    expect(find.text('You predicted: Sink'), findsOneWidget);
  });

  testWidgets('observing before predicting does nothing', (tester) async {
    await pumpActivity(tester, _activity);
    await observe(tester);
    expect(find.text('Continue'), findsNothing);
  });

  testWidgets('a confident wrong prediction is a celebrated surprise', (
    tester,
  ) async {
    final host = await pumpActivity(tester, _activity);
    await predict(tester, 'Sink', 'Totally sure');
    await observe(tester);

    expect(find.text('Whoa, a surprise!'), findsOneWidget);
    expect(
      find.textContaining('Lots of people think heavy-looking things sink.'),
      findsOneWidget,
    );
    expect(find.text('Float').hitTestable(), findsOneWidget);

    await tester.tap(find.text('Continue'));
    expect(host.results.single.xp, 5);
    expect(host.results.single.mistakes, 0);
  });

  testWidgets('a right prediction is called', (tester) async {
    await pumpActivity(tester, _activity);
    await predict(tester, 'Float', 'Pretty sure');
    await observe(tester);
    expect(find.text('You called it!'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsNothing);
  });

  test('titles follow rightness and confidence', () {
    for (final (right, confidence, title) in [
      (true, Confidence.guessing, 'Good guess!'),
      (true, Confidence.prettySure, 'You called it!'),
      (true, Confidence.certain, 'You called it!'),
      (false, Confidence.guessing, 'Now you know!'),
      (false, Confidence.prettySure, 'Surprise!'),
      (false, Confidence.certain, 'Whoa, a surprise!'),
    ]) {
      expect(predictionTitle(right: right, confidence: confidence), title);
    }
  });
}
