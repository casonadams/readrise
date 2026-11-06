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

  test('every lesson ends with something scored, not just reading', () {
    for (final lesson in course.lessons) {
      expect(
        lesson.activities.last is InfoCardActivity,
        isFalse,
        reason: '${lesson.id} ends with a reading card',
      );
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
}
