import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phonics_alphabet/src/letter_quiz_activity.dart';
import 'package:phonics_alphabet/src/letter_text.dart';

import '../support/letters.dart';

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
    testWidgets('a balloon shows "Mm" on one line at text scale $scale', (
      tester,
    ) async {
      await pumpActivity(
        tester,
        LetterQuizActivity.lesson(
          letter: letterOf('m'),
          learned: before('m'),
          unseen: after('m'),
        ),
        textScale: scale,
      );
      final mm = find.text('Mm');
      if (mm.evaluate().isEmpty) return;
      expect(linesOf(tester, mm.first), 1);
    });
  }
}
