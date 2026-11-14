import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:phonics_alphabet/src/letter_quiz_activity.dart';
import 'package:phonics_alphabet/src/letter_text.dart';
import 'package:phonics_alphabet/src/letters.dart';

import '../support/letters.dart';

List<String> balloons(WidgetTester tester) => [
  for (final w in tester.widgetList<LetterText>(find.byType(LetterText)))
    w.text,
];

Future<TestHost> pumpLesson(WidgetTester tester, String c) => pumpActivity(
  tester,
  LetterQuizActivity.lesson(
    letter: letterOf(c),
    learned: before(c),
    unseen: after(c),
  ),
);

Future<void> popRight(WidgetTester tester, TestHost host) async {
  await tester.tap(find.text(spokenLetter(host)!.display));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 800));
}

void main() {
  testWidgets('speaks the question and offers balloons including the answer', (
    tester,
  ) async {
    final host = await pumpLesson(tester, 's');
    expect((host.speaker as RecordingSpeaker).spoken, ['s']);
    expect(find.text('Tap the letter you hear'), findsOneWidget);
    expect(balloons(tester), hasLength(3));
    expect(balloons(tester), contains('Ss'));
  });

  testWidgets('popping the right balloon moves on to a picture question', (
    tester,
  ) async {
    final host = await pumpLesson(tester, 's');
    await popRight(tester, host);

    expect(find.text('Which letter does it start with?'), findsOneWidget);
    final said = (host.speaker as RecordingSpeaker).spoken;
    expect(said.last, 'sun');
    expect(find.text('\u2600\uFE0F'), findsOneWidget);
    expect(host.results, isEmpty);
  });

  testWidgets('a wrong balloon deflates in place and the question stays', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final host = await pumpLesson(tester, 's');
    final said = (host.speaker as RecordingSpeaker).spoken;
    final before = balloons(tester);
    final wrong = before.firstWhere((b) => b != 'Ss');

    await tester.tap(find.text(wrong));
    await tester.pump();

    expect(balloons(tester), before, reason: 'balloons keep their places');
    expect(
      find.bySemanticsLabel('Letter ${wrong[1]}, not this one'),
      findsOneWidget,
    );
    expect(said, ['s', 's'], reason: 'the prompt is repeated');
    expect(host.results, isEmpty);
    handle.dispose();
  });

  testWidgets('tapping an already deflated balloon does nothing', (
    tester,
  ) async {
    final host = await pumpLesson(tester, 's');
    final wrong = balloons(tester).firstWhere((b) => b != 'Ss');
    await tester.tap(find.text(wrong));
    await tester.pump();
    await tester.tap(find.text(wrong));
    await tester.pump();
    expect((host.speaker as RecordingSpeaker).spoken, ['s', 's']);
  });

  testWidgets('answering everything correctly finishes with full XP', (
    tester,
  ) async {
    final host = await pumpLesson(tester, 's');
    for (var i = 0; i < 3; i++) {
      await popRight(tester, host);
    }
    expect(host.results, hasLength(1));
    expect(host.results.single.xp, 30);
    expect(host.results.single.mistakes, 0);
  });

  testWidgets('mistakes are reported to the lesson', (tester) async {
    final host = await pumpLesson(tester, 's');
    final wrong = balloons(tester).firstWhere((b) => b != 'Ss');
    await tester.tap(find.text(wrong));
    await tester.pump();
    for (var i = 0; i < 4; i++) {
      if (host.results.isNotEmpty) break;
      await popRight(tester, host);
    }
    expect(host.results.single.mistakes, 1);
    expect(host.results.single.xp, 25);
  });

  testWidgets('a review quiz covers a whole set and ends with a score', (
    tester,
  ) async {
    final set = letterSets[0];
    final host = await pumpActivity(
      tester,
      LetterQuizActivity.review(letters: set, known: set),
    );
    var questions = 0;
    while (host.results.isEmpty && questions < 20) {
      await popRight(tester, host);
      questions++;
    }
    expect(questions, set.length * 2);
    expect(host.results.single.xp, set.length * 2 * 10);
  });

  testWidgets('four balloons once many letters are known', (tester) async {
    await pumpLesson(tester, 'g');
    expect(balloons(tester), hasLength(4));
  });

  testWidgets('balloons bob unless the user reduced motion', (tester) async {
    await pumpActivity(
      tester,
      LetterQuizActivity.lesson(
        letter: letterOf('s'),
        learned: const [],
        unseen: after('s'),
      ),
      animations: true,
    );
    final before = tester.getTopLeft(find.text('Ss'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.getTopLeft(find.text('Ss')), isNot(before));

    await pumpActivity(
      tester,
      LetterQuizActivity.lesson(
        letter: letterOf('s'),
        learned: const [],
        unseen: after('s'),
      ),
    );
    final still = tester.getTopLeft(find.text('Ss'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.getTopLeft(find.text('Ss')), still);
  });

  test('each attempt orders the questions by its own seed', () {
    final quiz = LetterQuizActivity.lesson(
      letter: letterOf('m'),
      learned: before('m'),
      unseen: after('m'),
    );
    final seeds = {for (var s = 0; s < 10; s++) quiz.shuffled(Random(s)).seed};
    expect(seeds, hasLength(greaterThan(1)));
  });
}
