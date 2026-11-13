import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_kit/science_kit.dart';

Widget _view({
  required bool reduceMotion,
  MatterState state = MatterState.gas,
}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: SizedBox(width: 300, height: 200, child: ParticleView(state: state)),
  ),
);

void main() {
  testWidgets('animates when motion is allowed', (tester) async {
    await tester.pumpWidget(_view(reduceMotion: false));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.hasScheduledFrame, isTrue);
  });

  testWidgets('with reduced motion, draws one still frame', (tester) async {
    await tester.pumpWidget(_view(reduceMotion: true));
    await tester.pump();
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);

    await tester.pumpWidget(
      _view(reduceMotion: true, state: MatterState.liquid),
    );
    await tester.pump();
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
