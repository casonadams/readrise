import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phonics_alphabet/src/letter_quiz_activity.dart';
import 'package:phonics_alphabet/src/letter_text.dart';
import 'package:phonics_alphabet/src/letters.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

class _Host implements ActivityHost {
  @override
  Speaker get speaker => _Silent();

  @override
  void complete(ActivityResult result) {}
}

class _Silent implements Speaker {
  @override
  Future<void> speak(String text) async {}
}

int linesOf(WidgetTester tester, Finder text) {
  final paragraph = tester.renderObject<RenderParagraph>(text);
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(
      baseOffset: 0,
      extentOffset: paragraph.text.toPlainText().length,
    ),
  );
  return boxes.map((b) => b.top.round()).toSet().length;
}

Widget quizApp(double textScale) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: Scaffold(
    body: Builder(
      builder: (context) => LetterQuizActivity(
        letter: set2[2],
        learned: set1,
        unseen: const [],
      ).build(context, _Host()),
    ),
  ),
);

void main() {
  testWidgets('LetterText stays on one line in a narrow space', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox(
            width: 30,
            child: LetterText('Mm', style: TextStyle(fontSize: 40)),
          ),
        ),
      ),
    );
    expect(linesOf(tester, find.text('Mm')), 1);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('answer button shows "Mm" on one line at text scale $scale', (
      tester,
    ) async {
      await tester.pumpWidget(quizApp(scale));
      await tester.pump();
      expect(linesOf(tester, find.text('Mm')), 1);
    });
  }

  testWidgets('answer button fits "Mm" at full size without shrinking it', (
    tester,
  ) async {
    await tester.pumpWidget(quizApp(1));
    await tester.pump();
    final fitted = find.ancestor(
      of: find.text('Mm'),
      matching: find.byType(FittedBox),
    );
    expect(
      tester.getSize(fitted).width,
      greaterThanOrEqualTo(tester.getSize(find.text('Mm')).width),
    );
  });
}
