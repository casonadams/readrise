import 'package:flutter_test/flutter_test.dart';
import 'package:readrise/engine/progress.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

import '../support/fake_plugins.dart';
import '../support/pump_app.dart';

void main() {
  final registry = buildSubjectRegistry();

  testWidgets('first launch offers to start and lists both subjects', (
    tester,
  ) async {
    await pumpApp(tester, registry);

    expect(find.text('Start learning'.toUpperCase()), findsOneWidget);
    expect(find.text('La'), findsOneWidget);
    expect(find.text('Reading'), findsOneWidget);
    expect(find.text('Science'), findsOneWidget);
    expect(find.text('3 lessons'), findsOneWidget);
    expect(find.text('2 lessons'), findsOneWidget);
  });

  testWidgets('Continue points at the next lesson and subjects show progress', (
    tester,
  ) async {
    await pumpApp(tester, registry, progress: finished(registry, ['r1/a']));

    expect(find.text('Continue'.toUpperCase()), findsOneWidget);
    expect(find.text('Lb'), findsOneWidget);
    expect(find.text('1 of 3 lessons'), findsOneWidget);
  });

  testWidgets('shows the streak and XP', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(
      tester,
      registry,
      progress: finished(registry, ['r1/a', 'r1/b'], xp: 20),
    );

    expect(find.bySemanticsLabel('1 day streak'), findsOneWidget);
    expect(find.bySemanticsLabel('40 XP'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('tapping a subject opens its path', (tester) async {
    await pumpApp(tester, registry);

    await tester.tap(find.text('Science'));
    await tester.pumpAndSettle();

    expect(find.text('\u{1F52C} Science'), findsOneWidget);
    expect(find.text('Lx'), findsOneWidget);
    expect(find.text('Lc'), findsNothing);
  });

  testWidgets('tapping Continue opens that lesson', (tester) async {
    await pumpApp(tester, registry, progress: finished(registry, ['r1/a']));

    await tester.tap(find.text('Lb'));
    await tester.pumpAndSettle();

    expect(find.text('finish b'), findsOneWidget);
  });

  testWidgets('when everything is done it says so', (tester) async {
    await pumpApp(
      tester,
      registry,
      progress: finished(registry, ['r1/a', 'r1/b', 'r2/c', 's1/x', 's1/y']),
    );

    expect(find.textContaining('All caught up'), findsOneWidget);
    expect(find.text('All 3 lessons done'), findsOneWidget);
    expect(find.text('Continue'.toUpperCase()), findsNothing);
  });

  testWidgets('a lapsed streak shows zero', (tester) async {
    final handle = tester.ensureSemantics();
    final old = const Progress().recordLesson(
      course: registry.courseById(const CourseId('r1')),
      lesson: registry.courseById(const CourseId('r1')).lessons.first,
      outcome: const LessonOutcome(xp: 5, mistakes: 0),
      today: DateTime(2026, 3, 1),
    );
    await pumpApp(tester, registry, progress: old);

    expect(old.streak, 1);
    expect(find.bySemanticsLabel('0 day streak'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a coming-soon subject is shown but cannot be opened', (
    tester,
  ) async {
    await pumpApp(tester, registry, closedSubjects: {'reading'});

    expect(find.text('Reading'), findsOneWidget);
    expect(find.text('Coming soon'), findsOneWidget);
    expect(find.text('Lx'), findsOneWidget);

    await tester.tap(find.text('Reading'));
    await tester.pumpAndSettle();
    expect(find.text('Pick a subject'), findsOneWidget);
  });
}
