import 'package:activity_kit/activity_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';
import 'package:readrise_testing/readrise_testing.dart';

void main() {
  final fake = ContentFaker();
  final own = [fake.question(), fake.question()];
  final pool = [fake.question(), fake.question(), fake.question()];
  final warmUp = WarmUpQuiz(questions: own, pool: pool);

  testWidgets('asks its own questions until the engine picks', (tester) async {
    await pumpActivity(tester, warmUp);
    expect(find.text(own.first.prompt), findsOneWidget);
    expect(find.text('Warm-up'), findsOneWidget);
  });

  test('reviews the picked pool questions, in the order picked', () {
    final reviewing = warmUp.reviewing([pool[2].id, pool[0].id]);
    expect(reviewing.kind, ActivityKind.warmUp);
    expect(reviewing.questions, [pool[2], pool[0]]);
  });

  test('offers the pool for review and keeps stats for its own questions', () {
    expect(warmUp.reviewable, pool.map((q) => q.id));
    expect(warmUp.reviewSize, own.length);
    expect(warmUp.items, own.map((q) => q.id));
  });

  randomizableContract<ActivityPlugin>(
    'warm-up',
    warmUp,
    arrangement: (activity) => switch (activity) {
      WarmUpQuiz(:final questions) || ChoiceQuizActivity(:final questions) => [
        for (final q in questions) ...[q.prompt, ...q.choices],
      ],
      _ => throw StateError('not a quiz: $activity'),
    },
  );
}
