import 'curriculum.dart';

DateTime dateOnly(DateTime t) => DateTime.utc(t.year, t.month, t.day);

class Progress {
  const Progress({
    this.xp = 0,
    this.streak = 0,
    this.lastPractice,
    this.stars = const {},
  });

  factory Progress.fromJson(Map<String, dynamic> json) => Progress(
    xp: json['xp'] as int? ?? 0,
    streak: json['streak'] as int? ?? 0,
    lastPractice: switch (json['lastPractice']) {
      final String s => DateTime.parse(s),
      _ => null,
    },
    stars: {
      for (final e in (json['stars'] as Map? ?? {}).entries)
        e.key as String: e.value as int,
    },
  );

  final int xp;
  final int streak;
  final DateTime? lastPractice;

  /// Best stars per lesson id.
  final Map<String, int> stars;

  Map<String, dynamic> toJson() => {
    'xp': xp,
    'streak': streak,
    'lastPractice': lastPractice?.toIso8601String(),
    'stars': stars,
  };

  int starsFor(Lesson lesson) => stars[lesson.id] ?? 0;

  bool isCourseComplete(Course course) =>
      course.lessons.every((l) => starsFor(l) > 0);

  bool isCourseUnlocked(Curriculum c, Course course) =>
      course.requires.every((id) => isCourseComplete(c.courseById(id)));

  /// Open when the course is open and the previous lesson has a star.
  bool isLessonUnlocked(Curriculum c, Course course, Lesson lesson) {
    if (!isCourseUnlocked(c, course)) return false;
    final i = course.lessons.indexOf(lesson);
    return i == 0 || starsFor(course.lessons[i - 1]) > 0;
  }

  /// Streak as shown on [today]: lapses to 0 after a missed day.
  int streakOn(DateTime today) {
    final last = lastPractice;
    if (last == null) return 0;
    final gap = dateOnly(today).difference(dateOnly(last)).inDays;
    return gap <= 1 ? streak : 0;
  }

  Progress recordLesson({
    required Lesson lesson,
    required int earnedStars,
    required int earnedXp,
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
    final best = starsFor(lesson);
    return Progress(
      xp: xp + earnedXp,
      streak: nextStreak,
      lastPractice: day,
      stars: {...stars, lesson.id: earnedStars > best ? earnedStars : best},
    );
  }
}
