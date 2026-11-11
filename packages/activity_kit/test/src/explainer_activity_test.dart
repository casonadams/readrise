import 'package:activity_kit/activity_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/recording_host.dart';

const _activity = ExplainerActivity(
  title: 'Matter',
  steps: [ExplainerStep('First idea.'), ExplainerStep('Second idea.')],
  scene: _scene,
);

Widget _scene(BuildContext context, int step) => Text('scene $step');

void main() {
  testWidgets('walks the steps forward and back, then completes', (
    tester,
  ) async {
    final host = await pumpActivity(tester, _activity);

    expect(find.text('First idea.'), findsOneWidget);
    expect(find.text('scene 0'), findsOneWidget);
    expect(find.byTooltip('Previous step'), findsNothing);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Second idea.'), findsOneWidget);
    expect(find.text('scene 1'), findsOneWidget);
    expect(host.results, isEmpty);

    await tester.tap(find.byTooltip('Previous step'));
    await tester.pumpAndSettle();
    expect(find.text('First idea.'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    expect(host.results, hasLength(1));
  });
}
