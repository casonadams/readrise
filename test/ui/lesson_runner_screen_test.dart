import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:readrise/engine/registry.dart';
import 'package:readrise/state/providers.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

import '../support/fake_plugins.dart';
import '../support/pump_app.dart';

PluginRegistry twoStepRegistry() => PluginRegistry([
  FakeCourse.of('a', [
    FakeLesson(
      '1',
      activities: const [
        FakeActivity('first', ActivityResult(xp: 10, mistakes: 1)),
        FakeActivity('second', ActivityResult(xp: 5, mistakes: 1)),
      ],
    ),
    FakeLesson('2'),
  ]),
]);

Future<void> openFirstLesson(WidgetTester tester) async {
  await tester.tap(find.text('L1'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('runs activities in order and sums their XP and mistakes', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final registry = twoStepRegistry();
    await pumpApp(tester, registry);
    await openFirstLesson(tester);

    expect(find.text('second'), findsNothing);
    await tester.tap(find.text('first'));
    await tester.pumpAndSettle();
    expect(find.text('first'), findsNothing);
    await tester.tap(find.text('second'));
    await tester.pumpAndSettle();

    expect(find.text('+15 XP'), findsOneWidget);
    expect(find.bySemanticsLabel('2 of 3 stars'), findsOneWidget);
    expect(find.text('Great job!'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('the progress bar shows which step you are on', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester, twoStepRegistry());
    await openFirstLesson(tester);
    expect(find.bySemanticsLabel('Step 1 of 2'), findsOneWidget);

    await tester.tap(find.text('first'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Step 2 of 2'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('finishing offers the next lesson and records progress', (
    tester,
  ) async {
    final registry = twoStepRegistry();
    await pumpApp(tester, registry);
    await openFirstLesson(tester);
    await tester.tap(find.text('first'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('second'));
    await tester.pumpAndSettle();

    expect(find.text('Next: L2'), findsOneWidget);
    await tester.tap(find.text('Next: L2'));
    await tester.pumpAndSettle();
    expect(find.text('finish 2'), findsOneWidget);
  });

  testWidgets('Back to the path returns to the subject and shows the stars', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester, buildRegistry());
    await tester.tap(find.text('Reading'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('L1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('finish 1'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Back to the path'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('L1, 3 of 3 stars'), findsOneWidget);
    expect(find.bySemanticsLabel('L2, start here'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('the last lesson of a subject offers only Back', (tester) async {
    await pumpApp(
      tester,
      PluginRegistry([
        FakeCourse('a', ['1', '2']),
      ]),
    );
    await tester.tap(find.text('Reading'));
    await tester.pumpAndSettle();
    for (final lesson in ['1', '2']) {
      await tester.tap(find.text('L$lesson'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('finish $lesson'));
      await tester.pumpAndSettle();
      if (lesson != '2') {
        await tester.tap(find.text('Back to the path'));
        await tester.pumpAndSettle();
      }
    }

    expect(find.textContaining('Next:'), findsNothing);
    expect(find.text('Back to the path'), findsOneWidget);
  });

  testWidgets('answers are saved when their activity finishes', (tester) async {
    final container = await pumpApp(
      tester,
      PluginRegistry([
        FakeCourse.of('a', [
          FakeLesson(
            '1',
            activities: const [
              FakeActivity('first', ActivityResult(), [
                Answer(ItemId('q1'), firstTry: false),
              ]),
              FakeActivity('second'),
            ],
          ),
        ]),
      ]),
    );
    await openFirstLesson(tester);
    await tester.tap(find.text('first'));
    await tester.pumpAndSettle();

    final stats = container
        .read(progressProvider)
        .itemsIn(const CourseId('a'))[const ItemId('q1')];
    expect((stats?.seen, stats?.box), (1, 0));
    expect(container.read(progressProvider).stars, isEmpty);
  });

  group('leaving mid-lesson', () {
    testWidgets('on the first step leaves without asking', (tester) async {
      await pumpApp(tester, twoStepRegistry());
      await openFirstLesson(tester);

      await tester.tap(find.byTooltip('Leave lesson'));
      await tester.pumpAndSettle();

      expect(find.text('Leave this lesson?'), findsNothing);
      expect(find.text('L1'), findsOneWidget);
    });

    testWidgets('later on, asks first and Keep going stays', (tester) async {
      await pumpApp(tester, twoStepRegistry());
      await openFirstLesson(tester);
      await tester.tap(find.text('first'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Leave lesson'));
      await tester.pumpAndSettle();
      expect(find.text('Leave this lesson?'), findsOneWidget);

      await tester.tap(find.text('Keep going'));
      await tester.pumpAndSettle();
      expect(find.text('second'), findsOneWidget);
    });

    testWidgets('Leave keeps your place: reopening carries on, same order', (
      tester,
    ) async {
      var now = today;
      final container = await pumpApp(
        tester,
        PluginRegistry([
          FakeCourse.of('a', [
            FakeLesson(
              '1',
              activities: const [
                FakeShufflingActivity('first', ActivityResult(xp: 10)),
                FakeShufflingActivity('second', ActivityResult(xp: 5)),
              ],
            ),
          ]),
        ]),
        clock: () => now,
      );
      await openFirstLesson(tester);
      await tester.tap(find.textContaining('first'));
      await tester.pumpAndSettle();
      final second = tester.widget<Text>(find.textContaining('second')).data;

      await tester.tap(find.byTooltip('Leave lesson'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leave'));
      await tester.pumpAndSettle();
      expect(container.read(progressProvider).stars, isEmpty);

      now = now.add(const Duration(hours: 1));
      await openFirstLesson(tester);
      expect(find.text(second!), findsOneWidget);
      await tester.tap(find.text(second));
      await tester.pumpAndSettle();
      expect(find.text('+15 XP'), findsOneWidget);
    });

    testWidgets('a finished lesson starts again from the first step', (
      tester,
    ) async {
      await pumpApp(tester, twoStepRegistry());
      await openFirstLesson(tester);
      await tester.tap(find.text('first'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('second'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Back to the path'));
      await tester.pumpAndSettle();

      GoRouter.of(tester.element(find.byType(Scaffold).first))
          .push('/lesson/a/1');
      await tester.pumpAndSettle();
      expect(find.text('first'), findsOneWidget);
    });
  });
}
