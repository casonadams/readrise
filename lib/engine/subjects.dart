import 'package:readrise_plugin_api/readrise_plugin_api.dart';

import 'progress.dart';
import 'registry.dart';

class LessonRef {
  const LessonRef(this.course, this.lesson);

  final CoursePlugin course;
  final LessonPlugin lesson;
}

class SubjectSummary {
  const SubjectSummary({
    required this.subject,
    required this.courses,
    required this.lessonsDone,
    required this.lessonsTotal,
    required this.next,
  });

  final Subject subject;
  final List<CoursePlugin> courses;
  final int lessonsDone;
  final int lessonsTotal;

  /// First open lesson without a star, or null when finished or all locked.
  final LessonRef? next;

  double get fraction => lessonsTotal == 0 ? 0 : lessonsDone / lessonsTotal;
  bool get started => lessonsDone > 0;
  bool get finished => lessonsDone == lessonsTotal;
}

/// One summary per subject, in the order subjects first appear in [registry].
List<SubjectSummary> summarizeSubjects(
  PluginRegistry registry,
  Progress progress,
) {
  final byId = <String, List<CoursePlugin>>{};
  for (final course in registry.courses) {
    byId.putIfAbsent(course.subject.id, () => []).add(course);
  }
  return [
    for (final courses in byId.values)
      SubjectSummary(
        subject: courses.first.subject,
        courses: courses,
        lessonsDone: [
          for (final c in courses)
            for (final l in c.lessons)
              if (progress.starsFor(c, l) > 0) l,
        ].length,
        lessonsTotal: courses.fold(0, (n, c) => n + c.lessons.length),
        next: _firstOpen(registry, progress, courses),
      ),
  ];
}

/// The first open lesson that has no star yet, within [subjectId] or anywhere.
LessonRef? nextUp(
  PluginRegistry registry,
  Progress progress, {
  String? subjectId,
}) => _firstOpen(registry, progress, [
  for (final c in registry.courses)
    if (subjectId == null || c.subject.id == subjectId) c,
]);

/// Where "Continue" should lead: the next lesson in the subject the learner
/// last practiced, else the next open lesson anywhere.
LessonRef? continueTarget(PluginRegistry registry, Progress progress) {
  final last = progress.lastLesson;
  if (last != null) {
    final courseId = last.split('/').first;
    for (final c in registry.courses) {
      if (c.id == courseId) {
        final inSubject = nextUp(registry, progress, subjectId: c.subject.id);
        if (inSubject != null) return inSubject;
      }
    }
  }
  return nextUp(registry, progress);
}

LessonRef? _firstOpen(
  PluginRegistry registry,
  Progress progress,
  Iterable<CoursePlugin> courses,
) {
  for (final course in courses) {
    for (final lesson in course.lessons) {
      if (progress.starsFor(course, lesson) == 0 &&
          progress.isLessonUnlocked(registry, course, lesson)) {
        return LessonRef(course, lesson);
      }
    }
  }
  return null;
}
