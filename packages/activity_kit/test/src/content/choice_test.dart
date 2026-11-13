import 'package:activity_kit/activity_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';
import 'package:readrise_testing/readrise_testing.dart';

void main() {
  final fake = ContentFaker();
  ChoiceQuizActivity quiz(ChoiceQuestion q) =>
      ChoiceQuizActivity(questions: [q]);

  final invalid = <String, Validated>{
    'a question without a right choice': quiz(
      fake.question(choices: [fake.wrong(), fake.wrong()]),
    ),
    'a question with two right choices': quiz(
      fake.question(choices: [fake.right(), fake.right()]),
    ),
    'a reason with two right choices': quiz(
      fake.question(reason: fake.reason(choices: [fake.right(), fake.right()])),
    ),
    'a prediction without a right choice': fake.prediction(
      const StandInExperiment(),
      choices: [fake.wrong(), fake.wrong()],
    ),
    'claims with two right choices': fake.debate(
      claims: [fake.right(), fake.right()],
    ),
    'a shuffled choice that points at the others': quiz(
      fake.question(
        choices: [fake.right(), fake.wrong(), Wrong('All of the above', 'No.')],
      ),
    ),
    'a sort item whose bin is missing': SortActivity(
      prompt: fake.sentence(),
      bins: [SortBin(fake.phrase())],
      items: [SortItem(fake.phrase(), bin: SortBin(fake.phrase()))],
    ),
  };
  invalid.forEach((name, content) {
    test('rejects $name', () {
      expect(content.validate, throwsArgumentError);
    });
  });
}
