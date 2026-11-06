import 'package:activity_kit/activity_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/recording_host.dart';

void main() {
  testWidgets('shows title, body and visual, and Continue completes', (
    tester,
  ) async {
    final host = await pumpActivity(
      tester,
      InfoCardActivity(
        title: 'Matter',
        body: 'Everything is made of particles.',
        visual: (_) => const Text('picture'),
      ),
    );

    expect(find.text('Matter'), findsOneWidget);
    expect(find.text('Everything is made of particles.'), findsOneWidget);
    expect(find.text('picture'), findsOneWidget);
    expect(host.results, isEmpty);

    await tester.tap(find.text('Continue'));
    expect(host.results, hasLength(1));
    expect(host.results.single.xp, 0);
    expect(host.results.single.mistakes, 0);
  });
}
