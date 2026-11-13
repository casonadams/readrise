import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phonics_alphabet/src/letter.dart';
import 'package:phonics_alphabet/src/letters.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

Letter letterOf(String char) => allLetters.firstWhere((l) => l.char == char);

/// Letters taught before / after [char] in the full alphabet order.
List<Letter> before(String char) =>
    allLetters.take(allLetters.indexOf(letterOf(char))).toList();

List<Letter> after(String char) =>
    allLetters.skip(allLetters.indexOf(letterOf(char)) + 1).toList();

class RecordingSpeaker implements Speaker {
  final List<String> spoken = [];

  @override
  Future<void> speak(String text) async => spoken.add(text);
}

class TestHost implements ActivityHost {
  TestHost([Speaker? speaker]) : speaker = speaker ?? RecordingSpeaker();

  @override
  final Speaker speaker;

  final List<Answer> answers = [];
  final List<ActivityResult> results = [];

  @override
  void record(Answer answer) => answers.add(answer);

  @override
  void complete(ActivityResult result) => results.add(result);
}

/// Wraps [activity] in a themed app with animations off, so a test can pump
/// and settle. Returns the host the activity reports to.
Future<TestHost> pumpActivity(
  WidgetTester tester,
  ActivityPlugin activity, {
  TestHost? host,
  bool animations = false,
  double textScale = 1,
}) async {
  final h = host ?? TestHost();
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          disableAnimations: !animations,
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(
          body: Builder(builder: (context) => activity.build(context, h)),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return h;
}

/// The letter whose word or letter name was last spoken.
Letter? spokenLetter(TestHost host) {
  final said = (host.speaker as RecordingSpeaker).spoken.last;
  for (final l in allLetters) {
    if (l.char == said || l.pictures.any((p) => p.word == said)) return l;
  }
  return null;
}
