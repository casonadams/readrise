import 'package:activity_kit/activity_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

class _NoExperiment implements Experiment {
  const _NoExperiment();

  @override
  Never build(
    BuildContext context, {
    required bool active,
    required VoidCallback onObserved,
  }) => throw UnimplementedError();
}

const _kid = Kid('Mia', skin: Color(0xFFF1C27D), hair: Color(0xFF4E342E));

ChoiceQuizActivity _quiz(List<Choice> choices, {Reason? reason}) =>
    ChoiceQuizActivity(
      questions: [
        ChoiceQuestion(
          prompt: 'Q',
          choices: choices,
          explanation: 'x',
          reason: reason,
        ),
      ],
    );

void main() {
  final invalid = <String, Validated>{
    'a question without a right choice': _quiz([
      const Wrong('a', 'no'),
      const Wrong('b', 'no'),
    ]),
    'a question with two right choices': _quiz([
      const Right('a'),
      const Right('b'),
    ]),
    'a reason with two right choices': _quiz([
      const Right('a'),
      const Wrong('b', 'no'),
    ], reason: const Reason(choices: [Right('x'), Right('y')])),
    'a prediction without a right choice': const PredictActivity(
      question: 'Q',
      choices: [Wrong('a', 'hm'), Wrong('b', 'hm')],
      tryIt: 'Try',
      experiment: _NoExperiment(),
      outcome: 'O',
    ),
    'claims with two right choices': const WhoIsRightActivity(
      situation: 'S',
      claims: [Claim(_kid, Right('a')), Claim(_kid, Right('b'))],
      explanation: 'x',
    ),
    'a sort item whose bin is missing': const SortActivity(
      prompt: 'Sort',
      bins: [SortBin('Hot')],
      items: [SortItem('Ice', bin: SortBin('Cold'))],
    ),
  };
  invalid.forEach((name, content) {
    test('rejects $name', () {
      expect(content.validate, throwsArgumentError);
    });
  });
}
