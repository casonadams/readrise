import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phonics_alphabet/src/letter_intro_activity.dart';

import '../support/letters.dart';

List<String> underlined(WidgetTester tester) {
  final text = tester.widget<Text>(
    find.byWidgetPredicate((w) => w is Text && w.textSpan != null),
  );
  return [
    for (final span in (text.textSpan! as TextSpan).children!)
      if (span is TextSpan &&
          span.style?.decoration == TextDecoration.underline)
        span.text!,
  ];
}

void main() {
  testWidgets('says the letter, then the word after a pause', (tester) async {
    final host = await pumpActivity(tester, LetterIntroActivity(letterOf('a')));
    final said = (host.speaker as RecordingSpeaker).spoken;
    expect(said, ['a']);

    await tester.pump(const Duration(milliseconds: 300));
    expect(said, ['a']);

    await tester.pump(const Duration(milliseconds: 200));
    expect(said, ['a', 'apple']);
  });

  testWidgets('tapping again restarts instead of overlapping', (tester) async {
    final host = await pumpActivity(tester, LetterIntroActivity(letterOf('a')));
    final said = (host.speaker as RecordingSpeaker).spoken;
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Aa'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(said, ['a', 'a']);

    await tester.pump(const Duration(milliseconds: 200));
    expect(said, ['a', 'a', 'apple']);
  });

  testWidgets('leaving the screen during the pause says nothing more', (
    tester,
  ) async {
    final host = await pumpActivity(tester, LetterIntroActivity(letterOf('a')));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    expect((host.speaker as RecordingSpeaker).spoken, ['a']);
  });

  testWidgets('picks the letter out inside its word', (tester) async {
    await pumpActivity(tester, LetterIntroActivity(letterOf('b')));
    expect(find.text('Bb'), findsOneWidget);
    expect(find.text('\u{1F41D}'), findsOneWidget);
    expect(underlined(tester), ['b']);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('for x the highlighted letter is the one at the end of fox', (
    tester,
  ) async {
    await pumpActivity(tester, LetterIntroActivity(letterOf('x')));
    expect(underlined(tester), ['x']);
    final text = tester.widget<Text>(
      find.byWidgetPredicate((w) => w is Text && w.textSpan != null),
    );
    expect(text.textSpan!.toPlainText(), 'fox');
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Next finishes the activity with no score of its own', (
    tester,
  ) async {
    final host = await pumpActivity(tester, LetterIntroActivity(letterOf('a')));
    await tester.tap(find.text('Next'));
    expect(host.results, hasLength(1));
    expect(host.results.single.xp, 0);
    expect(host.results.single.mistakes, 0);
    await tester.pump(const Duration(seconds: 1));
  });
}
