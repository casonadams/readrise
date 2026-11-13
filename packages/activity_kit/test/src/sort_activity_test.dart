import 'package:activity_kit/activity_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/recording_host.dart';

const _hot = SortBin('Hot');
const _cold = SortBin('Cold');

const activity = SortActivity(
  prompt: 'Sort them',
  bins: [_hot, _cold],
  items: [
    SortItem('Fire', bin: _hot),
    SortItem('Ice', bin: _cold),
  ],
);

void main() {
  testWidgets('tapping the right bins places items and finishes', (
    tester,
  ) async {
    final host = await pumpActivity(tester, activity);

    expect(find.text('Fire'), findsOneWidget);
    await tester.tap(find.text('Hot'));
    await tester.pump();
    expect(find.byKey(const ValueKey('placed:Fire')), findsOneWidget);
    expect(find.text('Ice'), findsOneWidget);

    await tester.tap(find.text('Cold'));
    await tester.pump();
    expect(find.text('All sorted!'), findsOneWidget);

    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    expect(host.results.single.xp, 20);
    expect(host.results.single.mistakes, 0);
  });

  testWidgets('a wrong bin keeps the item, counts a mistake, halves credit', (
    tester,
  ) async {
    final host = await pumpActivity(tester, activity);

    await tester.tap(find.text('Cold'));
    await tester.pump();
    expect(find.byKey(const ValueKey('placed:Fire')), findsNothing);
    expect(find.text('Fire'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(find.text('Hot'));
    await tester.pump();
    await tester.tap(find.text('Cold'));
    await tester.pump();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));

    expect(host.results.single.mistakes, 1);
    expect(host.results.single.xp, 15);
  });

  testWidgets('dragging an item onto its bin places it', (tester) async {
    await pumpActivity(tester, activity);

    await tester.drag(
      find.text('Fire'),
      tester.getCenter(find.text('Hot')) -
          tester.getCenter(find.text('Fire')) +
          const Offset(0, 40),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('placed:Fire')), findsOneWidget);
  });
  testWidgets('a long label wraps in a narrow bin instead of being cut off', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpActivity(
      tester,
      const SortActivity(
        prompt: 'Sort',
        bins: [SortBin('One'), SortBin('Two'), SortBin('Three')],
        items: [
          SortItem('Extraordinarily long label here', bin: SortBin('One')),
        ],
      ),
    );
    await tester.tap(find.text('One'));
    await tester.pump();

    final placed = find.descendant(
      of: find.byKey(const ValueKey('placed:Extraordinarily long label here')),
      matching: find.byType(Text),
    );
    final paragraph = tester.renderObject<RenderParagraph>(placed);
    expect(paragraph.didExceedMaxLines, isFalse);
    final lines = paragraph
        .getBoxesForSelection(
          const TextSelection(baseOffset: 0, extentOffset: 31),
        )
        .map((b) => b.top.round())
        .toSet();
    expect(lines.length, greaterThan(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('placing an item says why it belongs there', (tester) async {
    await pumpActivity(
      tester,
      const SortActivity(
        prompt: 'Sort',
        bins: [_hot, _cold],
        items: [SortItem('Fire', bin: _hot, why: 'Fire gives off heat.')],
      ),
    );
    await tester.tap(find.text('Hot'));
    await tester.pump();
    expect(find.text('Fire gives off heat.'), findsOneWidget);
  });

  const hinted = SortActivity(
    prompt: 'Sort',
    bins: [_hot, _cold],
    hint: 'Hot things warm you up.',
    items: [
      SortItem('Fire', bin: _hot),
      SortItem('Ice', bin: _cold),
    ],
  );

  testWidgets('a wrong bin answers with the hint', (tester) async {
    await pumpActivity(tester, hinted);
    await tester.tap(find.text('Cold'));
    await tester.pump();
    expect(find.text('Hot things warm you up.'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('asking for the hint halves that item only', (tester) async {
    final host = await pumpActivity(tester, hinted);
    await tester.tap(find.text('Need a hint?'));
    await tester.pump();
    expect(find.text('Hot things warm you up.'), findsOneWidget);

    await tester.tap(find.text('Hot'));
    await tester.pump();
    await tester.tap(find.text('Cold'));
    await tester.pump();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    expect(host.results.single.xp, 15);
    expect(host.results.single.mistakes, 0);
  });

  testWidgets('a bin announces its name and what is in it', (tester) async {
    await pumpActivity(tester, activity);
    expect(find.bySemanticsLabel('Hot'), findsOneWidget);
    await tester.tap(find.text('Hot'));
    await tester.pump();
    expect(find.bySemanticsLabel('Hot, 1 item: Fire'), findsOneWidget);
  });
}
