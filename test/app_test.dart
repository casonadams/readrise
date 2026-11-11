import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phonics_alphabet/src/letters.dart';
import 'package:readrise/engine/registry.dart';
import 'package:readrise/plugins.dart';

import 'support/fake_plugins.dart';
import 'support/pump_app.dart';

String lastSpoken(FakeSpeaker s) => s.spoken.last;

/// The trace screen draws its letter mask with a real image call, which only
/// completes on real time.
Future<void> letterMaskLoaded(WidgetTester tester) async {
  await tester.pump();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 300)),
  );
  await tester.pump();
}

void main() {
  testWidgets('a learner completes the whole first lesson, Ss', (tester) async {
    final handle = tester.ensureSemantics();
    final speaker = FakeSpeaker();
    await pumpApp(tester, PluginRegistry(installedCourses()), speaker: speaker);

    await tester.tap(find.text('Reading'));
    await tester.pumpAndSettle();
    expect(find.text('Alphabet 1: S A T P'), findsOneWidget);
    expect(find.bySemanticsLabel('Ss, start here'), findsOneWidget);

    await tester.tap(find.text('Ss'));
    await tester.pumpAndSettle();

    // Meet the letter.
    expect(find.text('Tap to hear'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await letterMaskLoaded(tester);

    // Trace it (skipped here; drawing is covered by the trace tests).
    expect(find.text('Trace the big letter'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await letterMaskLoaded(tester);
    expect(find.text('Trace the small letter'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    // Pop the balloons.
    for (var i = 0; i < 3; i++) {
      final said = lastSpoken(speaker);
      final letter = allLetters.firstWhere(
        (l) => l.char == said || l.pictures.any((p) => p.word == said),
      );
      await tester.tap(find.text(letter.display));
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pumpAndSettle();

    // Feed the monster.
    expect(find.text('Feed me things that start with'), findsOneWidget);
    for (var i = 0; i < 6; i++) {
      final good = allLetters.first.pictures.any(
        (p) => p.word == lastSpoken(speaker),
      );
      await tester.tap(find.byKey(Key(good ? 'monster' : 'bin')));
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pumpAndSettle();

    expect(find.text('Perfect!'), findsOneWidget);
    expect(find.text('+60 XP'), findsOneWidget);
    expect(find.text('Next: Aa'), findsOneWidget);
    await tester.tap(find.text('Back to the path'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Ss, 3 of 3 stars'), findsOneWidget);
    expect(find.bySemanticsLabel('Aa, start here'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('1 day streak'), findsOneWidget);
    expect(find.bySemanticsLabel('60 XP'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('every installed lesson can be opened without errors', (
    tester,
  ) async {
    final registry = PluginRegistry(installedCourses());
    for (final course in registry.courses) {
      for (final lesson in course.lessons) {
        await tester.pumpWidget(const SizedBox());
        final host = FakeSpeaker();
        await pumpApp(
          tester,
          registry,
          speaker: host,
          progress: finished(registry, [
            for (final c in registry.courses)
              for (final l in c.lessons)
                if (c != course || l != lesson) '${c.id}/${l.id}',
          ]),
        );
        final target = Uri.encodeFull('/lesson/${course.id}/${lesson.id}');
        final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
        router.push(target);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(
          tester.takeException(),
          isNull,
          reason: '${course.id}/${lesson.id}',
        );
        await tester.pump(const Duration(seconds: 2));
      }
    }
  });
}
