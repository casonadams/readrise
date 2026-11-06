import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phonics_alphabet/src/letter_intro_activity.dart';
import 'package:phonics_alphabet/src/letters.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

class RecordingSpeaker implements Speaker {
  final List<String> spoken = [];

  @override
  Future<void> speak(String text) async => spoken.add(text);
}

class _Host implements ActivityHost {
  _Host(this.speaker);

  @override
  final Speaker speaker;

  @override
  void complete(ActivityResult result) {}
}

Future<RecordingSpeaker> pumpIntro(WidgetTester tester) async {
  final speaker = RecordingSpeaker();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) =>
              LetterIntroActivity(set1[1]).build(context, _Host(speaker)),
        ),
      ),
    ),
  );
  await tester.pump();
  return speaker;
}

void main() {
  testWidgets('says the letter, then the word after a pause', (tester) async {
    final speaker = await pumpIntro(tester);
    expect(speaker.spoken, ['a']);

    await tester.pump(const Duration(milliseconds: 300));
    expect(speaker.spoken, ['a']);

    await tester.pump(const Duration(milliseconds: 200));
    expect(speaker.spoken, ['a', 'apple']);
  });

  testWidgets('tapping again restarts instead of overlapping', (tester) async {
    final speaker = await pumpIntro(tester);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Aa'));
    await tester.pump(const Duration(milliseconds: 250));

    expect(speaker.spoken, ['a', 'a']);

    await tester.pump(const Duration(milliseconds: 200));
    expect(speaker.spoken, ['a', 'a', 'apple']);
  });

  testWidgets('leaving the screen during the pause says nothing more', (
    tester,
  ) async {
    final speaker = await pumpIntro(tester);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    expect(speaker.spoken, ['a']);
  });
}
