import 'package:activity_kit/activity_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _pageKey = Key('page');

Widget _app({Widget? feedback, void Function(double)? onCovered}) =>
    MaterialApp(
      home: Scaffold(
        body: FeedbackLayout(
          feedback: feedback,
          page: (context, covered) {
            onCovered?.call(covered);
            return const Column(
              children: [
                Text('question'),
                Expanded(
                  child: ColoredBox(key: _pageKey, color: Colors.blue),
                ),
              ],
            );
          },
        ),
      ),
    );

const _banner = FeedbackBanner(
  key: ValueKey('wrong'),
  kind: FeedbackKind.wrong,
  message: 'Not that one.',
);

void main() {
  testWidgets('feedback slides over the page without moving or resizing it', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    final before = tester.getRect(find.byKey(_pageKey));

    await tester.pumpWidget(_app(feedback: _banner));
    await tester.pumpAndSettle();

    expect(tester.getRect(find.byKey(_pageKey)), before);
    final banner = tester.getRect(find.byType(FeedbackBanner));
    expect(banner.bottom, before.bottom);
    expect(banner.top, greaterThan(before.top));
  });

  testWidgets('the page learns how much the feedback covers', (tester) async {
    var covered = -1.0;
    await tester.pumpWidget(_app(onCovered: (c) => covered = c));
    expect(covered, 0);

    await tester.pumpWidget(
      _app(feedback: _banner, onCovered: (c) => covered = c),
    );
    await tester.pumpAndSettle();
    expect(covered, tester.getSize(find.byType(FeedbackBanner)).height);

    await tester.pumpWidget(_app(onCovered: (c) => covered = c));
    await tester.pumpAndSettle();
    expect(covered, 0);
  });

  testWidgets('a new message replaces the old one', (tester) async {
    await tester.pumpWidget(_app(feedback: _banner));
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      _app(
        feedback: const FeedbackBanner(
          key: ValueKey('hint'),
          kind: FeedbackKind.hint,
          message: 'Think about it.',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Not that one.'), findsNothing);
    expect(find.text('Think about it.'), findsOneWidget);
  });
}
