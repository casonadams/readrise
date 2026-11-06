import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readrise/ui/widgets/lesson_node.dart';

Widget host(
  NodeState state, {
  VoidCallback? onTap,
  int stars = 0,
  double textScale = 1,
  bool reduceMotion = false,
}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(
      textScaler: TextScaler.linear(textScale),
      disableAnimations: reduceMotion,
    ),
    child: Scaffold(
      body: Center(
        child: LessonNode(
          title: 'Matter',
          state: state,
          stars: stars,
          onTap: onTap ?? () {},
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('every state can be tapped, including locked', (tester) async {
    for (final state in NodeState.values) {
      var taps = 0;
      await tester.pumpWidget(host(state, onTap: () => taps++));
      await tester.tap(find.byType(LessonNode));
      expect(taps, 1, reason: state.name);
    }
  });

  testWidgets('only the current lesson shows START; locked shows a lock', (
    tester,
  ) async {
    await tester.pumpWidget(host(NodeState.current));
    expect(find.text('START'), findsOneWidget);

    await tester.pumpWidget(host(NodeState.locked));
    expect(find.text('START'), findsNothing);
    expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    expect(find.text('Matter'), findsNothing);
  });

  testWidgets('a finished lesson shows its stars', (tester) async {
    await tester.pumpWidget(host(NodeState.done, stars: 2));
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(2));
    expect(find.byIcon(Icons.star_outline_rounded), findsOneWidget);
  });

  testWidgets('the current lesson animates, unless motion is reduced', (
    tester,
  ) async {
    await tester.pumpWidget(host(NodeState.current));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.binding.hasScheduledFrame, isTrue);

    await tester.pumpWidget(host(NodeState.current, reduceMotion: true));
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  for (final state in NodeState.values) {
    testWidgets('${state.name} node does not overflow at 2x text size', (
      tester,
    ) async {
      await tester.pumpWidget(host(state, stars: 3, textScale: 2));
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a long title shrinks instead of wrapping', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: LessonNode(
              title: 'Changes of state',
              state: NodeState.done,
              stars: 1,
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    final paragraph = tester.renderObject<RenderParagraph>(
      find.text('Changes of state'),
    );
    final boxes = paragraph.getBoxesForSelection(
      const TextSelection(baseOffset: 0, extentOffset: 16),
    );
    expect(boxes.map((b) => b.top.round()).toSet(), hasLength(1));
    expect(tester.takeException(), isNull);
  });
}
