import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:readrise/engine/registry.dart';
import 'package:readrise/state/providers.dart';
import 'package:readrise/ui/lesson_runner_screen.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_plugins.dart';

Future<ProviderContainer> pumpRunner(
  WidgetTester tester,
  PluginRegistry registry,
) async {
  SharedPreferences.setMockInitialValues({});
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const Text('home')),
      GoRoute(
        path: '/lesson/:c/:l',
        builder: (_, s) => LessonRunnerScreen(
          courseId: s.pathParameters['c']!,
          lessonId: s.pathParameters['l']!,
        ),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
        registryProvider.overrideWithValue(registry),
        speakerProvider.overrideWithValue(FakeSpeaker()),
        clockProvider.overrideWithValue(() => DateTime(2026, 1, 1)),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  unawaited(router.push('/lesson/a/1'));
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
}

void main() {
  testWidgets('runs activities in order and sums their XP and mistakes', (
    tester,
  ) async {
    final registry = PluginRegistry([
      FakeCourse.of('a', [
        FakeLesson(
          '1',
          activities: const [
            FakeActivity('first', ActivityResult(xp: 10, mistakes: 1)),
            FakeActivity('second', ActivityResult(xp: 5, mistakes: 1)),
          ],
        ),
      ]),
    ]);
    final container = await pumpRunner(tester, registry);

    expect(find.text('second'), findsNothing);
    await tester.tap(find.text('first'));
    await tester.pumpAndSettle();
    expect(find.text('first'), findsNothing);
    await tester.tap(find.text('second'));
    await tester.pumpAndSettle();

    expect(find.text('+15 XP'), findsOneWidget);
    expect(find.text('\u2B50\u2B50\u2606'), findsOneWidget);
    final course = registry.courseById('a');
    expect(
      container.read(progressProvider).starsFor(course, course.lessons.first),
      2,
    );
    expect(container.read(progressProvider).xp, 15);
  });

  testWidgets('Continue returns to the previous screen', (tester) async {
    await pumpRunner(tester, buildRegistry());
    await tester.tap(find.text('finish 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
  });
}
