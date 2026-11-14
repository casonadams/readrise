import 'package:activity_kit/activity_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

import 'activity_host.dart';
import 'real_fonts.dart';
import 'scenes.dart';

const _experimentKey = Key('experiment');

/// Reports its result as soon as it may, so a test reaches the result panel.
class _ObservesAtOnce implements Experiment {
  const _ObservesAtOnce();

  @override
  Widget build(
    BuildContext context, {
    required bool active,
    required VoidCallback onObserved,
  }) {
    if (active) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onObserved());
    }
    return const SizedBox.expand(key: _experimentKey);
  }
}

/// The content rules from AGENTS.md that types and startup checks cannot
/// express, as tests every course with these activities runs.
void courseContentContract(CoursePlugin course) {
  final activities = [for (final l in course.lessons) ...l.activities];
  final questions = [
    for (final a in activities)
      ...switch (a) {
        ChoiceQuizActivity(:final questions) => questions,
        WarmUpQuiz(:final questions) => questions,
        _ => const <ChoiceQuestion>[],
      },
  ];

  group('${course.title} content', () {
    setUpAll(loadRoboto);

    test('every quiz question has distinct choices, a hint and an '
        'explanation', () {
      expect(questions, isNotEmpty);
      for (final q in questions) {
        final texts = q.choices.map((c) => c.text);
        expect(texts.toSet(), hasLength(texts.length), reason: q.prompt);
        expect(q.hint, isNotNull, reason: q.prompt);
        expect(q.explanation, isNotEmpty, reason: q.prompt);
      }
    });

    test('every sort uses every bin, has a hint, and says why for each '
        'item', () {
      for (final s in activities.whereType<SortActivity>()) {
        expect(
          s.items.map((i) => i.bin).toSet(),
          s.bins.toSet(),
          reason: s.prompt,
        );
        expect(s.hint, isNotNull, reason: s.prompt);
        for (final item in s.items) {
          expect(item.why, isNotNull, reason: item.label);
        }
      }
    });

    testWidgets('every explainer scene can show each of its steps', (
      tester,
    ) async {
      for (final e in activities.whereType<ExplainerActivity>()) {
        for (var step = 0; step < e.steps.length; step++) {
          await pumpScene(tester, e.scene, step);
          expect(tester.takeException(), isNull, reason: '${e.title} $step');
        }
      }
    });

    testWidgets('a prediction result never covers its experiment on a '
        'phone', (tester) async {
      // A 390x844 phone less the lesson runner's top bar.
      tester.view.physicalSize = const Size(390, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final p in activities.whereType<PredictActivity>()) {
        final probe = PredictActivity(
          question: p.question,
          choices: p.choices,
          tryIt: p.tryIt,
          outcome: p.outcome,
          experiment: const _ObservesAtOnce(),
        );
        for (final choice in p.choices) {
          await tester.pumpWidget(const SizedBox());
          await pumpActivity(tester, probe);
          await tester.tap(find.text(choice.text));
          await tester.pump();
          await tester.tap(find.text('Totally sure'));
          await tester.pumpAndSettle();
          expect(
            tester.getRect(find.byType(AnswerPanel)).top,
            greaterThanOrEqualTo(
              tester.getRect(find.byKey(_experimentKey)).bottom,
            ),
            reason: '${p.question} / ${choice.text}',
          );
        }
      }
    });
  });
}
