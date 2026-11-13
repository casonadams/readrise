import 'package:activity_kit/activity_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:readrise_testing/readrise_testing.dart';

const _mia = Kid('Mia', skin: Color(0xFFF1C27D), hair: Color(0xFF4E342E));
const _leo = Kid('Leo', skin: Color(0xFF8D5524), hair: Color(0xFF212121));

const _activity = WhoIsRightActivity(
  situation: 'Is air matter?',
  claims: [
    Claim(
      _mia,
      Wrong('Air is nothing.', 'Air fills balloons, so it is something.'),
    ),
    Claim(_leo, Right('Air has mass.')),
  ],
  explanation: 'Air takes up space and has mass.',
);

void main() {
  testWidgets('picking the right classmate first earns full credit', (
    tester,
  ) async {
    final host = await pumpActivity(tester, _activity);
    await tester.tap(find.textContaining('Air has mass.'));
    await tester.pumpAndSettle();
    expect(find.text('Yes! Leo is right.'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    expect(host.results.single.xp, 10);
    expect(host.results.single.mistakes, 0);
  });

  testWidgets('a wrong pick explains the misconception and halves credit', (
    tester,
  ) async {
    final host = await pumpActivity(tester, _activity);
    await tester.tap(find.textContaining('Air is nothing.'));
    await tester.pumpAndSettle();
    expect(
      find.text('Air fills balloons, so it is something.'),
      findsOneWidget,
    );
    expect(find.text('Continue'), findsNothing);

    await tester.tap(find.textContaining('Air has mass.'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    expect(host.results.single.xp, 5);
    expect(host.results.single.mistakes, 1);
  });
}
