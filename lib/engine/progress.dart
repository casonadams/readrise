import 'package:readrise_plugin_api/readrise_plugin_api.dart';

import 'registry.dart';

DateTime dateOnly(DateTime t) => DateTime.utc(t.year, t.month, t.day);

String lessonKey(CoursePlugin course, LessonPlugin lesson) =>
    '${course.id}/${lesson.id}';

/// Engine-owned scoring: plugins report mistakes and XP, never stars.
class LessonOutcome {
  const LessonOutcome({required this.xp, required this.mistakes});

  final int xp;
  final int mistakes;

  int get stars => switch (mistakes) {
    0 => 3,
    <= 2 => 2,
    _ => 1,
  };
}

class Progress {
  const Progress({
    this.xp = 0,
    this.streak = 0,
    this.lastPractice,
    this.lastLesson,
    this.stars = const {},
  });

  factory Progress.fromJson(Map<String, dynamic> json) => Progress(
    xp: json['xp'] as int? ?? 0,
    streak: json['streak'] as int? ?? 0,
    lastPractice: switch (json['lastPractice']) {
      final String s => DateTime.parse(s),
      _ => null,
    },
    lastLesson: json['lastLesson'] as String?,
    stars: {
      for (final e in (json['stars'] as Map? ?? {}).entries)
        e.key as String: e.value as int,
    },
  );

  final int xp;
  final int streak;
  final DateTime? lastPractice;

  /// [lessonKey] of the most recently finished lesson.
  final String? lastLesson;

  /// Best stars per [lessonKey].
  final Map<String, int> stars;

  Map<String, dynamic> toJson() => {
    'xp': xp,
    'streak': streak,
    'lastPractice': lastPractice?.toIso8601String(),
    'lastLesson': lastLesson,
    'stars': stars,
  };

  int starsFor(CoursePlugin course, LessonPlugin lesson) =>
      stars[lessonKey(course, lesson)] ?? 0;

  bool isCourseComplete(CoursePlugin course) =>
      course.lessons.every((l) => starsFor(course, l) > 0);

  bool isCourseUnlocked(PluginRegistry registry, CoursePlugin course) =>
      course.requires.every((id) => isCourseComplete(registry.courseById(id)));

  /// Open when the course is open and the previous lesson has a star.
  bool isLessonUnlocked(
    PluginRegistry registry,
    CoursePlugin course,
    LessonPlugin lesson,
  ) {
    if (!isCourseUnlocked(registry, course)) return false;
    final i = course.lessons.indexOf(lesson);
    return i == 0 || starsFor(course, course.lessons[i - 1]) > 0;
  }

  /// Streak as shown on [today]: lapses to 0 after a missed day.
  int streakOn(DateTime today) {
    final last = lastPractice;
    if (last == null) return 0;
    final gap = dateOnly(today).difference(dateOnly(last)).inDays;
    return gap <= 1 ? streak : 0;
  }

  Progress recordLesson({
    required CoursePlugin course,
    required LessonPlugin lesson,
    required LessonOutcome outcome,
    required DateTime today,
  }) {
    final day = dateOnly(today);
    final last = lastPractice;
    final gap = last == null ? null : day.difference(dateOnly(last)).inDays;
    final nextStreak = switch (gap) {
      0 => streak,
      1 => streak + 1,
      _ => 1,
    };
    final best = starsFor(course, lesson);
    return Progress(
      xp: xp + outcome.xp,
      streak: nextStreak,
      lastPractice: day,
      lastLesson: lessonKey(course, lesson),
      stars: {
        ...stars,
        lessonKey(course, lesson): outcome.stars > best ? outcome.stars : best,
      },
    );
  }
}
