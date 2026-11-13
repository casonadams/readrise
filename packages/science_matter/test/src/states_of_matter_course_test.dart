import 'package:activity_kit/activity_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_matter/science_matter.dart';

void main() {
  final course = StatesOfMatterCourse();
  final activities = [for (final l in course.lessons) ...l.activities];
  final questions = [
    for (final a in activities.whereType<ChoiceQuizActivity>()) ...a.questions,
  ];

  test('is open from the start and ordered matter, states, heat, changes', () {
    expect(course.requires, isEmpty);
    expect(course.lessons.map((l) => l.id.value), [
      'matter',
      'states',
      'heat',
      'changes',
    ]);
  });

  test(
    'every quiz question has distinct choices, a hint and an explanation',
    () {
      expect(questions, isNotEmpty);
      for (final q in questions) {
        final texts = q.choices.map((c) => c.text);
        expect(texts.toSet(), hasLength(texts.length), reason: q.prompt);
        expect(q.hint, isNotNull, reason: q.prompt);
        expect(q.explanation, isNotEmpty, reason: q.prompt);
      }
    },
  );

  test('every sort uses every bin, has a hint, and says why for each item', () {
    final sorts = activities.whereType<SortActivity>();
    expect(sorts, isNotEmpty);
    for (final s in sorts) {
      expect(
        s.items.map((i) => i.bin).toSet(),
        s.bins.toSet(),
        reason: s.prompt,
      );
      expect(s.hint, isNotNull, reason: s.prompt);
      for (final item in s.items) {
        expect(item.why, isNotNull, reason: item.label);
      }
    }
  });
}
