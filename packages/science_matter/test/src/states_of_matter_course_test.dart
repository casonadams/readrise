import 'package:activity_kit/activity_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_matter/science_matter.dart';

void main() {
  final course = StatesOfMatterCourse();
  final activities = [for (final l in course.lessons) ...l.activities];

  test('is open from the start and ordered matter, states, heat, changes', () {
    expect(course.requires, isEmpty);
    expect(course.lessons.map((l) => l.id), [
      'matter',
      'states',
      'heat',
      'changes',
    ]);
  });

  test(
    'lessons follow the arc: warm-up, one prediction first, debate last',
    () {
      for (final (i, lesson) in course.lessons.indexed) {
        final kinds = lesson.activities;
        if (i > 0) {
          expect(
            kinds.first,
            isA<ChoiceQuizActivity>().having(
              (q) => q.kind,
              'kind',
              ActivityKind.warmUp,
            ),
            reason: '${lesson.id} opens with a warm-up',
          );
        }
        final predicts = kinds.whereType<PredictActivity>();
        expect(predicts, hasLength(1), reason: lesson.id);
        expect(
          kinds.indexOf(predicts.single),
          lessThan(kinds.indexWhere((a) => a is ExplainerActivity)),
          reason: '${lesson.id} predicts before explaining',
        );
        expect(kinds.last, isA<WhoIsRightActivity>(), reason: lesson.id);
      }
    },
  );

  test('lesson ids are unique', () {
    final ids = course.lessons.map((l) => l.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('every wrong prediction gets a reaction', () {
    for (final p in activities.whereType<PredictActivity>()) {
      for (var i = 0; i < p.options.length; i++) {
        if (i == p.answer) continue;
        expect(p.reactions[i], isNotNull, reason: '${p.question} option $i');
      }
      expect(p.reactions.containsKey(p.answer), isFalse);
    }
  });

  test('every wrong claim and wrong reason is explained', () {
    for (final w in activities.whereType<WhoIsRightActivity>()) {
      for (var i = 0; i < w.claims.length; i++) {
        if (i == w.answer) continue;
        expect(w.feedback[i], isNotNull, reason: w.situation);
      }
    }
    for (final q in [
      for (final a in activities.whereType<ChoiceQuizActivity>())
        ...a.questions,
    ]) {
      final reason = q.reason;
      if (reason == null) continue;
      for (var i = 0; i < reason.options.length; i++) {
        if (i == reason.answer) continue;
        expect(reason.feedback[i], isNotNull, reason: q.prompt);
      }
    }
  });

  test('every quiz question has distinct options and a valid answer', () {
    final questions = [
      for (final a in activities.whereType<ChoiceQuizActivity>())
        ...a.questions,
    ];
    expect(questions, isNotEmpty);
    for (final q in questions) {
      expect(q.options.toSet(), hasLength(q.options.length), reason: q.prompt);
      expect(q.answer, inInclusiveRange(0, q.options.length - 1));
      expect(q.explanation, isNotEmpty);
    }
  });

  test('every sort item belongs to a real bin and every bin is used', () {
    final sorts = activities.whereType<SortActivity>();
    expect(sorts, isNotEmpty);
    for (final s in sorts) {
      for (final item in s.items) {
        expect(item.bin, inInclusiveRange(0, s.bins.length - 1));
      }
      expect(s.items.map((i) => i.bin).toSet(), hasLength(s.bins.length));
    }
  });

  test(
    'every quiz question has a hint and feedback only for wrong options',
    () {
      for (final q in [
        for (final a in activities.whereType<ChoiceQuizActivity>())
          ...a.questions,
      ]) {
        expect(q.hint, isNotNull, reason: q.prompt);
        expect(q.feedback, isNotEmpty, reason: q.prompt);
        for (final option in q.feedback.keys) {
          expect(option, inInclusiveRange(0, q.options.length - 1));
          expect(option, isNot(q.answer), reason: q.prompt);
        }
      }
    },
  );

  test('every sort has a hint and every item says why', () {
    for (final s in activities.whereType<SortActivity>()) {
      expect(s.hint, isNotNull, reason: s.prompt);
      for (final item in s.items) {
        expect(item.why, isNotNull, reason: item.label);
      }
    }
  });
}
