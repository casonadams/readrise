import 'package:flutter_test/flutter_test.dart';
import 'package:readrise/engine/progress.dart';
import 'package:readrise/engine/subjects.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

import '../support/fake_plugins.dart';

void main() {
  final registry = buildSubjectRegistry();
  final r1 = registry.courseById('r1');
  final r2 = registry.courseById('r2');
  final s1 = registry.courseById('s1');
  final day = DateTime(2026, 3, 8);

  Progress finish(Progress p, CoursePlugin c, int lesson) => p.recordLesson(
    course: c,
    lesson: c.lessons[lesson],
    outcome: const LessonOutcome(xp: 10, mistakes: 0),
    today: day,
  );

  String? idOf(LessonRef? ref) =>
      ref == null ? null : '${ref.course.id}/${ref.lesson.id}';

  group('summarizeSubjects', () {
    test('groups courses by subject in first-seen order with counts', () {
      final p = finish(const Progress(), r1, 0);
      final summaries = summarizeSubjects(registry, p);

      expect(summaries.map((s) => s.subject.id), ['reading', 'science']);
      final reading = summaries.first;
      expect(reading.courses.map((c) => c.id), ['r1', 'r2']);
      expect(reading.lessonsTotal, 3);
      expect(reading.lessonsDone, 1);
      expect(reading.fraction, closeTo(1 / 3, 1e-9));
      expect(reading.started, isTrue);
      expect(idOf(reading.next), 'r1/b');
      expect(summaries.last.started, isFalse);
      expect(idOf(summaries.last.next), 's1/x');
    });

    test('a finished subject has no next lesson', () {
      var p = const Progress();
      p = finish(finish(p, s1, 0), s1, 1);
      final science = summarizeSubjects(registry, p).last;
      expect(science.finished, isTrue);
      expect(science.next, isNull);
    });
  });

  group('nextUp', () {
    test('skips finished lessons and locked courses', () {
      var p = finish(const Progress(), r1, 0);
      expect(idOf(nextUp(registry, p, subjectId: 'reading')), 'r1/b');

      p = finish(p, r1, 1);
      expect(idOf(nextUp(registry, p, subjectId: 'reading')), 'r2/c');
    });
  });

  group('continueTarget', () {
    test('starts at the first open lesson when nothing is done', () {
      expect(idOf(continueTarget(registry, const Progress())), 'r1/a');
    });

    test('stays in the subject that was practiced last', () {
      final p = finish(finish(const Progress(), r1, 0), s1, 0);
      expect(p.lastLesson, 's1/x');
      expect(idOf(continueTarget(registry, p)), 's1/y');
    });

    test('falls back to another subject when the last one is finished', () {
      var p = finish(const Progress(), r1, 0);
      p = finish(finish(p, s1, 0), s1, 1);
      expect(idOf(continueTarget(registry, p)), 'r1/b');
    });

    test('is null when everything is finished', () {
      var p = const Progress();
      for (final c in [r1, r2, s1]) {
        for (var i = 0; i < c.lessons.length; i++) {
          p = finish(p, c, i);
        }
      }
      expect(continueTarget(registry, p), isNull);
    });
  });
}
