import 'dart:math';

import 'package:activity_kit/activity_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';
import 'package:readrise_testing/readrise_testing.dart';

void main() {
  final fake = ContentFaker();

  randomizableContract(
    'quiz',
    ChoiceQuizActivity(
      questions: [
        fake.question(reason: fake.reason()),
        fake.question(),
        fake.question(),
      ],
    ),
    arrangement: (quiz) => [
      for (final q in quiz.questions) ...[
        q.prompt,
        ...q.choices,
        ...?q.reason?.choices,
      ],
    ],
  );
  randomizableContract(
    'prediction',
    fake.prediction(
      const StandInExperiment(),
      choices: fake.choices(wrongs: 3),
    ),
    arrangement: (prediction) => prediction.choices,
  );
  randomizableContract(
    "who's right",
    fake.debate(claims: fake.choices(wrongs: 2)),
    arrangement: (debate) => debate.claims,
  );
  randomizableContract(
    'sort',
    fake.sort(itemsPerBin: 3),
    arrangement: (sort) => sort.items,
  );

  test('ordered choices and sort bins never move', () {
    final ordered = ChoiceQuestion(
      id: const ItemId('ordered'),
      prompt: fake.sentence(),
      choices: fake.choices(wrongs: 3),
      explanation: fake.sentence(),
      ordered: true,
    );
    final quiz = ChoiceQuizActivity(questions: [ordered]);
    final sort = fake.sort(bins: 3);
    for (var seed = 0; seed < 20; seed++) {
      expect(
        quiz.shuffled(Random(seed)).questions.single.choices,
        ordered.choices,
      );
      expect(sort.shuffled(Random(seed)).bins, sort.bins);
    }
  });
}
