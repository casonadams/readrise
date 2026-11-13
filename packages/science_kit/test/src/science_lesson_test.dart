import 'package:activity_kit/activity_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';
import 'package:readrise_testing/readrise_testing.dart';
import 'package:science_kit/science_kit.dart';

final _fake = ContentFaker();

ExplainerActivity _explainer(String title) => ExplainerActivity(
  title: title,
  steps: [ExplainerStep(_fake.sentence())],
  scene: (_, _) => const SizedBox(),
);

ScienceLesson _lesson(
  String id, {
  List<ScienceLesson>? recalls,
  List<ExplainerActivity>? explain,
}) => ScienceLesson(
  id: LessonId(id),
  title: id,
  warmUp: recalls == null
      ? null
      : WarmUp(recalls: recalls, questions: [_fake.question()]),
  predict: _fake.prediction(const StandInExperiment()),
  explain: explain ?? [_explainer('one'), _explainer('two')],
  practise: [_fake.sort()],
  check: [_fake.question()],
  debate: _fake.debate(),
);

void main() {
  test('activities follow the lesson arc', () {
    final kinds = [
      for (final a in _lesson('b', recalls: [_lesson('a')]).activities)
        switch (a) {
          WarmUpQuiz() => 'warmUp',
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
    'a warm-up recalling a later lesson': () {
      final a = _lesson('a');
      final c = _lesson('c', recalls: [a]);
      return [
        a,
        _lesson('b', recalls: [c]),
        c,
      ];
    },
    'a warm-up recalling its own lesson': () => [
      _lesson('a'),
      _lesson('b', recalls: [_lesson('b')]),
    ],
  };
  invalid.forEach((name, lessons) {
    test('warm-up check rejects $name', () {
      expect(() => checkWarmUps(lessons()), throwsArgumentError);
    });
  });

  test("a warm-up reviews the recalled lessons' check questions", () {
    final a = _lesson('a');
    final b = _lesson('b');
    final warmUp = _lesson('c', recalls: [a, b]).activities.first as WarmUpQuiz;
    expect(warmUp.reviewable, [
      ...a.check.map((q) => q.id),
      ...b.check.map((q) => q.id),
    ]);
    expect(warmUp.reviewSize, warmUp.questions.length);
  });
}
