import 'package:readrise_plugin_api/readrise_plugin_api.dart';

/// The installed course plugins, in learning order.
class PluginRegistry {
  PluginRegistry(List<CoursePlugin> courses)
    : courses = List.unmodifiable(courses) {
    final seen = <CourseId>{};
    final subjects = <String, Subject>{};
    for (final course in courses) {
      _checkId(course.id.value, 'course ${course.id}');
      if (!seen.add(course.id)) {
        throw ArgumentError('duplicate course ${course.id}');
      }
      for (final required in course.requires) {
        if (!seen.contains(required) || required == course.id) {
          throw ArgumentError(
            'course ${course.id} requires $required, which is not installed '
            'before it',
          );
        }
      }
      final known = subjects[course.subject.id];
      if (known != null && known != course.subject) {
        throw ArgumentError(
          'course ${course.id} declares subject ${course.subject.id} as '
          '"${course.subject.title}" but "${known.title}" was already registered',
        );
      }
      subjects[course.subject.id] = course.subject;
      if (course.lessons.isEmpty) {
        throw ArgumentError('course ${course.id} has no lessons');
      }
      final lessonIds = <LessonId>{};
      for (final lesson in course.lessons) {
        _checkId(lesson.id.value, 'lesson ${course.id}/${lesson.id}');
        if (!lessonIds.add(lesson.id)) {
          throw ArgumentError('duplicate lesson ${course.id}/${lesson.id}');
        }
        if (lesson.activities.isEmpty) {
          throw ArgumentError(
            'lesson ${course.id}/${lesson.id} has no activities',
          );
        }
      }
    }
  }

  /// Ids are stored as "course/lesson" and used as route segments.
  static void _checkId(String id, String what) {
    if (id.isEmpty || id.contains('/')) {
      throw ArgumentError('$what: an id must be non-empty and contain no "/"');
    }
  }

  final List<CoursePlugin> courses;

  CoursePlugin courseById(CourseId id) => courses.firstWhere(
    (c) => c.id == id,
    orElse: () => throw ArgumentError.value(id, 'id', 'unknown course'),
  );

  LessonPlugin lessonById(CourseId courseId, LessonId lessonId) =>
      courseById(courseId).lessons.firstWhere(
        (l) => l.id == lessonId,
        orElse: () =>
            throw ArgumentError.value(lessonId, 'lessonId', 'unknown lesson'),
      );
}
