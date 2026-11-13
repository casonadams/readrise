import 'package:activity_kit/activity_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';
import 'package:science_matter/src/lessons/classmates.dart';
import 'package:science_matter/src/lessons/science_lesson.dart';

class _StandIn implements Experiment {
  const _StandIn();

  @override
  Widget build(
    BuildContext context, {
    required bool active,
    required VoidCallback onObserved,
  }) => const SizedBox();
}

const _question = ChoiceQuestion(
  prompt: 'Q',
  choices: [Right('a'), Wrong('b', 'no')],
  explanation: 'x',
);

const _sort = SortActivity(
  prompt: 'Sort',
  bins: [SortBin('A')],
  items: [SortItem('a', bin: SortBin('A'))],
);

ExplainerActivity _explainer(String title) => ExplainerActivity(
  title: title,
  steps: const [ExplainerStep('step')],
  scene: (_, _) => const SizedBox(),
);

ScienceLesson _lesson(
  String id, {
  List<String>? recalls,
  List<ExplainerActivity>? explain,
}) => ScienceLesson(
  id: LessonId(id),
  title: id,
  warmUp: recalls == null
      ? null
      : WarmUp(
          recalls: [for (final r in recalls) LessonId(r)],
          questions: const [_question],
        ),
  predict: const PredictActivity(
    question: 'P',
    choices: [Right('a'), Wrong('b', 'hm')],
    tryIt: 'Try',
    experiment: _StandIn(),
    outcome: 'O',
  ),
  explain: explain ?? [_explainer('one'), _explainer('two')],
  practise: const [_sort],
  check: const [_question],
  debate: const WhoIsRightActivity(
    situation: 'S',
    claims: [Claim(mia, Right('a')), Claim(leo, Wrong('b', 'no'))],
    explanation: 'x',
  ),
);

void main() {
  test('activities follow the lesson arc', () {
    final kinds = [
      for (final a in _lesson('b', recalls: ['a']).activities)
        switch (a) {
          ChoiceQuizActivity(:final kind) => kind.name,
          PredictActivity() => 'predict',
          ExplainerActivity(:final title) => 'explain $title',
          SortActivity() => 'practise',
          WhoIsRightActivity() => 'debate',
          _ => a.runtimeType.toString(),
        },
    ];
    expect(kinds, [
      'warmUp',
      'predict',
      'explain one',
      'explain two',
      'practise',
      'check',
      'debate',
    ]);
  });

  test('a lesson without an explainer is rejected', () {
    expect(() => _lesson('a', explain: []), throwsArgumentError);
  });

  final invalid = <String, List<ScienceLesson> Function()>{
    'a first lesson with a warm-up': () => [_lesson('a', recalls: [])],
    'a later lesson without a warm-up': () => [_lesson('a'), _lesson('b')],
    'a warm-up recalling a later lesson': () => [
      _lesson('a'),
      _lesson('b', recalls: ['c']),
      _lesson('c', recalls: ['a']),
    ],
    'a warm-up recalling its own lesson': () => [
      _lesson('a'),
      _lesson('b', recalls: ['b']),
    ],
  };
  invalid.forEach((name, lessons) {
    test('warm-up check rejects $name', () {
      expect(() => checkWarmUps(lessons()), throwsArgumentError);
    });
  });
}
