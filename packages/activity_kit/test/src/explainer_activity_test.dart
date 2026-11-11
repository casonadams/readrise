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
  testWidgets('walks the steps, speaking each caption, then completes', (
    tester,
  ) async {
    final host = await pumpActivity(tester, _activity);
    final spoken = host.recordingSpeaker.spoken;

    expect(find.text('First idea.'), findsOneWidget);
    expect(find.text('scene 0'), findsOneWidget);
    expect(spoken, ['First idea.']);
    expect(find.byTooltip('Previous step'), findsNothing);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Second idea.'), findsOneWidget);
    expect(find.text('scene 1'), findsOneWidget);
    expect(spoken.last, 'Second idea.');
    expect(host.results, isEmpty);

    await tester.tap(find.byTooltip('Previous step'));
    await tester.pumpAndSettle();
    expect(find.text('First idea.'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    expect(host.results, hasLength(1));
  });

  testWidgets('sound off stops narration until turned back on', (tester) async {
    final host = await pumpActivity(tester, _activity);
    final spoken = host.recordingSpeaker.spoken;

    await tester.tap(find.byTooltip('Turn sound off'));
    await tester.pump();
    spoken.clear();

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(spoken, isEmpty);

    await tester.tap(find.byTooltip('Turn sound on'));
    await tester.pump();
    expect(spoken, ['Second idea.']);
  });

  testWidgets('a card replacing another explainer still narrates', (
    tester,
  ) async {
    const next = ExplainerActivity(
      title: 'Next',
      steps: [ExplainerStep('Next card.')],
      scene: _scene,
    );
    final host = RecordingHost();
    Widget app(int index) => MaterialApp(
      home: Scaffold(
        body: KeyedSubtree(
          key: ValueKey(index),
          child: Builder(
            builder: (context) =>
                (index == 0 ? _activity : next).build(context, host),
          ),
        ),
      ),
    );

    await tester.pumpWidget(app(0));
    await tester.pumpWidget(app(1));
    await tester.pump();

    expect(host.recordingSpeaker.spoken.last, 'Next card.');
  });
}
