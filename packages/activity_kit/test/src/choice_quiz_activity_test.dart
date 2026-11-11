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

void main() {
  testWidgets('a perfect run reports full XP and no mistakes', (tester) async {
    final host = await pumpActivity(
      tester,
      const ChoiceQuizActivity(questions: questions),
    );

    await tester.tap(find.text('yes'));
    await tester.pumpAndSettle();
    expect(find.text('Because one.'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Second?'), findsOneWidget);
    expect(find.text('Because one.'), findsNothing);
    await tester.tap(find.text('right'));
    await tester.pumpAndSettle();
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
    await tester.pumpAndSettle();
    await tester.tap(find.text('no'));
    await tester.pumpAndSettle();
    expect(find.text('Because one.'), findsNothing);

    await tester.tap(find.text('yes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('right'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));

    expect(host.results.single.mistakes, 1);
    expect(host.results.single.xp, 15);
  });

  testWidgets('cannot continue before answering correctly', (tester) async {
    await pumpActivity(tester, const ChoiceQuizActivity(questions: questions));
    expect(find.text('Continue'), findsNothing);
    await tester.tap(find.text('nope'));
    await tester.pumpAndSettle();
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

  testWidgets('a wrong pick explains why that option is wrong', (tester) async {
    await pumpActivity(
      tester,
      const ChoiceQuizActivity(
        questions: [
          ChoiceQuestion(
            prompt: 'Q',
            options: ['a', 'b', 'c'],
            answer: 2,
            explanation: 'x',
            feedback: {0: 'a is a trap.'},
          ),
        ],
      ),
    );

    await tester.tap(find.text('a'));
    await tester.pumpAndSettle();
    expect(find.text('a is a trap.'), findsOneWidget);

    await tester.tap(find.text('b'));
    await tester.pumpAndSettle();
    expect(find.text('a is a trap.'), findsNothing);
    expect(find.text('Not quite. Try another answer.'), findsOneWidget);
  });

  const hinted = ChoiceQuizActivity(
    questions: [
      ChoiceQuestion(
        prompt: 'Q',
        options: ['a', 'b', 'c', 'd'],
        answer: 3,
        explanation: 'x',
        hint: 'Think about d.',
      ),
    ],
  );

  testWidgets('asking for the hint shows it and halves the credit', (
    tester,
  ) async {
    final host = await pumpActivity(tester, hinted);
    expect(find.text('Think about d.'), findsNothing);

    await tester.tap(find.text('Need a hint?'));
    await tester.pumpAndSettle();
    expect(find.text('Think about d.'), findsOneWidget);

    await tester.tap(find.text('d'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    expect(host.results.single.xp, 10);
    expect(host.results.single.mistakes, 0);
  });

  testWidgets('the hint appears on its own after two misses', (tester) async {
    await pumpActivity(tester, hinted);

    await tester.tap(find.text('a'));
    await tester.pumpAndSettle();
    expect(find.text('Think about d.'), findsNothing);

    await tester.tap(find.text('b'));
    await tester.pumpAndSettle();
    expect(find.text('Think about d.'), findsOneWidget);
  });

  testWidgets('options announce whether they were wrong or correct', (
    tester,
  ) async {
    await pumpActivity(tester, const ChoiceQuizActivity(questions: questions));
    await tester.tap(find.text('no'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('no, wrong'), findsOneWidget);
    await tester.tap(find.text('yes'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('yes, correct'), findsOneWidget);
  });

  const twoTier = ChoiceQuizActivity(
    questions: [
      ChoiceQuestion(
        prompt: 'Q',
        options: ['wrong', 'right'],
        answer: 1,
        explanation: 'Because.',
        reason: Reason(
          options: ['bad reason', 'good reason'],
          answer: 1,
          feedback: {0: 'That reason is a myth.'},
        ),
      ),
    ],
  );

  testWidgets('a two-tier question asks why before explaining', (tester) async {
    final host = await pumpActivity(tester, twoTier);
    expect(find.text('good reason'), findsNothing);

    await tester.tap(find.text('right'));
    await tester.pumpAndSettle();
    expect(find.text('Why is that?'), findsOneWidget);
    expect(find.text('Because.'), findsNothing);

    await tester.tap(find.text('good reason'));
    await tester.pumpAndSettle();
    expect(find.text('Because.'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    expect(host.results.single.xp, 20);
  });

  testWidgets('a wrong reason is explained, counted, and halves credit', (
    tester,
  ) async {
    final host = await pumpActivity(tester, twoTier);
    await tester.tap(find.text('right'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('bad reason'));
    await tester.pumpAndSettle();
    expect(find.text('That reason is a myth.'), findsOneWidget);
    expect(find.text('Because.'), findsNothing);

    await tester.tap(find.text('good reason'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    expect(host.results.single.xp, 10);
    expect(host.results.single.mistakes, 1);
  });

  testWidgets('the header names the kind of quiz', (tester) async {
    await pumpActivity(
      tester,
      const ChoiceQuizActivity(questions: questions, kind: ActivityKind.warmUp),
    );
    expect(find.text('Warm-up'), findsOneWidget);
  });
}
