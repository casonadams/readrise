import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readrise/app.dart';
import 'package:readrise/data/curriculum_loader.dart';
import 'package:readrise/data/speaker.dart';
import 'package:readrise/domain/curriculum.dart';
import 'package:readrise/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSpeaker implements Speaker {
  String? last;

  @override
  Future<void> speak(String text) async => last = text;
}

void main() {
  testWidgets('completing the first lesson earns stars and unlocks the next', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final curriculum = (await tester.runAsync(
      () => loadCurriculum(rootBundle),
    ))!;
    final speaker = _FakeSpeaker();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          curriculumProvider.overrideWithValue(curriculum),
          speakerProvider.overrideWithValue(speaker),
          clockProvider.overrideWithValue(() => DateTime(2026, 1, 1)),
        ],
        child: const ReadriseApp(),
      ),
    );

    final first = curriculum.lessons.first as LetterLesson;
    final letters = [first.letter];
    await tester.tap(find.text('Ss'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    while (find.text('Continue').evaluate().isEmpty) {
      final spoken = speaker.last;
      final target = letters.firstWhere(
        (l) => l.sound == spoken || l.word == spoken,
      );
      await tester.tap(find.text('${target.upper}${target.char}'));
      await tester.pump(const Duration(seconds: 1));
    }

    expect(find.text('+30 XP'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('\u{1F525} 1'), findsOneWidget);
    expect(find.text('\u2B50 30'), findsOneWidget);
    expect(find.text('Aa'), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsWidgets);
  });
}
