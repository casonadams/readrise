import 'package:flutter_test/flutter_test.dart';
import 'package:readrise/engine/registry.dart';
import 'package:readrise/plugins.dart';

import 'support/fake_plugins.dart';
import 'support/pump_app.dart';

void main() {
  testWidgets('a learner picks Reading, finishes Ss, and sees progress', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final speaker = FakeSpeaker();
    await pumpApp(tester, PluginRegistry(installedCourses()), speaker: speaker);

    await tester.tap(find.text('Reading'));
    await tester.pumpAndSettle();
    expect(find.text('Alphabet 1'), findsOneWidget);
    expect(find.bySemanticsLabel('Ss, start here'), findsOneWidget);

    await tester.tap(find.text('Ss'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    while (find.text('Back to the path').evaluate().isEmpty) {
      expect(speaker.spoken.last, anyOf('s', 'sun'));
      await tester.tap(find.text('Ss'));
      await tester.pump(const Duration(seconds: 1));
    }

    expect(find.text('+30 XP'), findsOneWidget);
    expect(find.text('Perfect!'), findsOneWidget);
    expect(find.text('Next: Aa'), findsOneWidget);
    await tester.tap(find.text('Back to the path'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Ss, 3 of 3 stars'), findsOneWidget);
    expect(find.bySemanticsLabel('Aa, start here'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('1 day streak'), findsOneWidget);
    expect(find.bySemanticsLabel('30 XP'), findsOneWidget);
    expect(find.text('Continue'.toUpperCase()), findsOneWidget);
    expect(find.text('Aa'), findsOneWidget);
    handle.dispose();
  });
}
