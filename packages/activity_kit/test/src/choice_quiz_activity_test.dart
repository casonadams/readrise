import 'package:activity_kit/activity_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/recording_host.dart';

const questions = [
  ChoiceQuestion(
    prompt: 'First?',
    options: ['no', 'yes', 'nope'],
    answer: 1,
    explanation: 'Because one.',
  ),
  ChoiceQuestion(
    prompt: 'Second?',
    options: ['right', 'wrong'],
    answer: 0,
    explanation: 'Because two.',
  ),
];

bool isEnabled(WidgetTester tester, String label) =>
    tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, label))
        .onPressed !=
    null;

void main() {
  testWidgets('a perfect run reports full XP and no mistakes', (tester) async {
    final host = await pumpActivity(
      tester,
      const ChoiceQuizActivity(questions: questions),
    );

    await tester.tap(find.text('yes'));
    await tester.pump();
    expect(find.text('Because one.'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(find.text('Second?'), findsOneWidget);
    expect(find.text('Because one.'), findsNothing);
    await tester.tap(find.text('right'));
    await tester.pump();
    await tester.tap(find.text('Continue'));

    expect(host.results.single.xp, 20);
    expect(host.results.single.mistakes, 0);
  });

  testWidgets('a wrong pick is disabled, counted, and halves that credit', (
    tester,
  ) async {
    final host = await pumpActivity(
      tester,
      const ChoiceQuizActivity(questions: questions),
    );

    await tester.tap(find.text('no'));
    await tester.pump();
    expect(isEnabled(tester, 'no'), isFalse);
    expect(find.text('Because one.'), findsNothing);

    await tester.tap(find.text('yes'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.tap(find.text('right'));
    await tester.pump();
    await tester.tap(find.text('Continue'));

    expect(host.results.single.mistakes, 1);
    expect(host.results.single.xp, 15);
  });

  testWidgets('cannot continue before answering correctly', (tester) async {
    await pumpActivity(tester, const ChoiceQuizActivity(questions: questions));
    expect(find.text('Continue'), findsNothing);
    await tester.tap(find.text('nope'));
    await tester.pump();
    expect(find.text('Continue'), findsNothing);
  });

  testWidgets('shows a question visual when given', (tester) async {
    await pumpActivity(
      tester,
      ChoiceQuizActivity(
        questions: [
          ChoiceQuestion(
            prompt: 'Look',
            options: const ['a', 'b'],
            answer: 0,
            explanation: 'x',
            visual: (_) => const Text('diagram'),
          ),
        ],
      ),
    );
    expect(find.text('diagram'), findsOneWidget);
  });
}
