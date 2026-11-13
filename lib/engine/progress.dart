import 'package:readrise_plugin_api/readrise_plugin_api.dart';

import 'item_stats.dart';
import 'registry.dart';

DateTime dateOnly(DateTime t) => DateTime.utc(t.year, t.month, t.day);

/// Where a lesson's progress is stored.
typedef LessonKey = ({CourseId course, LessonId lesson});

LessonKey lessonKey(CoursePlugin course, LessonPlugin lesson) =>
    (course: course.id, lesson: lesson.id);

String encodeLessonKey(LessonKey key) =>
    '${key.course.value}/${key.lesson.value}';

LessonKey decodeLessonKey(String text) => switch (text.split('/')) {
  [final course, final lesson] => (
    course: CourseId(course),
    lesson: LessonId(lesson),
  ),
  _ => throw FormatException('not a "course/lesson" key', text),
};

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
    this.items = const {},
  });

  factory Progress.fromJson(Map<String, dynamic> json) => Progress(
    xp: json['xp'] as int? ?? 0,
    streak: json['streak'] as int? ?? 0,
    lastPractice: switch (json['lastPractice']) {
      final String s => DateTime.parse(s),
      _ => null,
    },
    lastLesson: switch (json['lastLesson']) {
      final String s => decodeLessonKey(s),
      _ => null,
    },
    stars: {
      for (final e in (json['stars'] as Map? ?? {}).entries)
        decodeLessonKey(e.key as String): e.value as int,
    },
    items: {
      for (final e in (json['items'] as Map? ?? {}).entries)
        decodeItemKey(e.key as String): ItemStats.fromJson(
          e.value as Map<String, dynamic>,
        ),
    },
  );

  final int xp;
  final int streak;
  final DateTime? lastPractice;

  /// The most recently finished lesson.
  final LessonKey? lastLesson;

  /// Best stars per lesson.
  final Map<LessonKey, int> stars;

  /// Per-question stats; saves from before they existed have none.
  final Map<ItemKey, ItemStats> items;

  Map<String, dynamic> toJson() => {
    'xp': xp,
    'streak': streak,
    'lastPractice': lastPractice?.toIso8601String(),
    'lastLesson': switch (lastLesson) {
      final LessonKey key => encodeLessonKey(key),
      null => null,
    },
    'stars': {for (final e in stars.entries) encodeLessonKey(e.key): e.value},
    'items': {
      for (final e in items.entries) encodeItemKey(e.key): e.value.toJson(),
    },
  };

  int starsFor(CoursePlugin course, LessonPlugin lesson) =>
      stars[lessonKey(course, lesson)] ?? 0;

  /// The stats of [course]'s items the learner has answered.
  Map<ItemId, ItemStats> itemsIn(CourseId course) => {
    for (final e in items.entries)
      if (e.key.course == course) e.key.item: e.value,
  };

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
      items: items,
    );
  }

  /// Progress after [answers] to items of [course] at [now]. Stars, XP and
  /// streak change only when a lesson is finished.
  Progress recordAnswers({
    required CourseId course,
    required List<Answer> answers,
    required DateTime now,
  }) {
    final next = {...items};
    for (final answer in answers) {
      final key = (course: course, item: answer.item);
      next[key] = ItemStats.answered(
        next[key],
        firstTry: answer.firstTry,
        now: now,
      );
    }
    return Progress(
      xp: xp,
      streak: streak,
      lastPractice: lastPractice,
      lastLesson: lastLesson,
      stars: stars,
      items: next,
    );
  }
}
