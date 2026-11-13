import 'package:activity_kit/activity_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';
import 'package:readrise_testing/readrise_testing.dart';
import 'package:science_matter/src/lessons/science_lesson.dart';

final _fake = ContentFaker();

ExplainerActivity _explainer(String title) => ExplainerActivity(
  title: title,
  steps: [ExplainerStep(_fake.sentence())],
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
          questions: [_fake.question()],
        ),
  predict: _fake.prediction(const StandInExperiment()),
  explain: explain ?? [_explainer('one'), _explainer('two')],
  practise: [_fake.sort()],
  check: [_fake.question()],
  debate: _fake.debate(),
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
