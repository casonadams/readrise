import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phonics_alphabet/phonics_alphabet.dart';
import 'package:readrise/app.dart';
import 'package:readrise/engine/registry.dart';
import 'package:readrise/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_plugins.dart';

void main() {
  testWidgets(
    'learner finishes the first alphabet lesson and unlocks the next',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final speaker = FakeSpeaker();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(
              await SharedPreferences.getInstance(),
            ),
            registryProvider.overrideWithValue(
              PluginRegistry([AlphabetCourse.set1(), AlphabetCourse.set2()]),
            ),
            speakerProvider.overrideWithValue(speaker),
            clockProvider.overrideWithValue(() => DateTime(2026, 1, 1)),
          ],
          child: const ReadriseApp(),
        ),
      );

      expect(find.text('Alphabet 1'), findsOneWidget);
      await tester.tap(find.text('Ss'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();

      while (find.text('Continue').evaluate().isEmpty) {
        final spoken = speaker.spoken.last;
        final target = spoken == 'sss' || spoken == 'sun'
            ? 'Ss'
            : fail('unexpected prompt $spoken');
        await tester.tap(find.text(target));
        await tester.pump(const Duration(seconds: 1));
      }

      expect(find.text('+30 XP'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('\u{1F525} 1'), findsOneWidget);
      expect(find.text('\u2B50 30'), findsOneWidget);
      expect(find.text('Aa'), findsOneWidget);
      expect(find.byIcon(Icons.lock), findsWidgets);
    },
  );
}
