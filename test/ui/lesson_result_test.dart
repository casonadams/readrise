import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readrise/engine/progress.dart';
import 'package:readrise/engine/subjects.dart';
import 'package:readrise/ui/lesson_result.dart';
import 'package:readrise/ui/widgets/confetti.dart';

import '../support/fake_plugins.dart';

Future<void> pumpResult(
  WidgetTester tester, {
  int mistakes = 0,
  int xp = 30,
  int streak = 0,
  bool hasNext = true,
  VoidCallback? onNext,
  VoidCallback? onBack,
}) async {
  final course = FakeCourse('a', ['1', '2']);
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: LessonResult(
          outcome: LessonOutcome(xp: xp, mistakes: mistakes),
          streak: streak,
          next: hasNext ? LessonRef(course, course.lessons[1]) : null,
          onNext: onNext ?? () {},
          onBack: onBack ?? () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final cases = {
    0: ('Perfect!', 3),
    2: ('Great job!', 2),
    5: ('Nice work!', 1),
  };
  cases.forEach((mistakes, expected) {
    testWidgets('$mistakes mistakes -> "${expected.$1}" and '
        '${expected.$2} stars', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpResult(tester, mistakes: mistakes);
      expect(find.text(expected.$1), findsOneWidget);
      expect(
        find.bySemanticsLabel('${expected.$2} of 3 stars'),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  testWidgets('shows the XP earned', (tester) async {
    await pumpResult(tester, xp: 45);
    expect(find.text('+45 XP'), findsOneWidget);
  });

  testWidgets('confetti only for two stars or more', (tester) async {
    await pumpResult(tester, mistakes: 0);
    expect(find.byType(Confetti), findsOneWidget);

    await pumpResult(tester, mistakes: 9);
    expect(find.byType(Confetti), findsNothing);
  });

  testWidgets('shows the streak only when there is one', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpResult(tester, streak: 4);
    expect(find.bySemanticsLabel('4 day streak'), findsOneWidget);

    await pumpResult(tester, streak: 0);
    expect(find.bySemanticsLabel('0 day streak'), findsNothing);
    handle.dispose();
  });

  testWidgets('offers the next lesson, with Back as the quieter option', (
    tester,
  ) async {
    var next = 0, back = 0;
    await pumpResult(tester, onNext: () => next++, onBack: () => back++);

    await tester.tap(find.text('Next: L2'));
    await tester.tap(find.text('Back to the path'));

    expect(next, 1);
    expect(back, 1);
    expect(find.byType(TextButton), findsOneWidget);
  });

  testWidgets('with nothing next, Back becomes the main button', (
    tester,
  ) async {
    await pumpResult(tester, hasNext: false);
    expect(find.textContaining('Next:'), findsNothing);
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.text('Back to the path'), findsOneWidget);
  });

  testWidgets('lays out on a small phone at large text without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(640, 960);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            textScaler: const TextScaler.linear(1.8),
            disableAnimations: true,
          ),
          child: LessonResult(
            outcome: const LessonOutcome(xp: 30, mistakes: 0),
            streak: 12,
            next: LessonRef(
              FakeCourse('a', ['1', '2']),
              FakeCourse('a', ['1', '2']).lessons[1],
            ),
            onNext: () {},
            onBack: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
