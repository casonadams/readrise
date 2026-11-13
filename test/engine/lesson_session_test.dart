import 'package:flutter_test/flutter_test.dart';
import 'package:readrise/engine/lesson_session.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

const _key = (course: CourseId('a'), lesson: LessonId('1'));

void main() {
  test('moves on and adds up XP and mistakes until the last activity', () {
    const start = LessonSession(lesson: _key, seed: 7);
    final step = start.advance(
      const ActivityResult(xp: 10, mistakes: 1),
      activityCount: 2,
    );
    final next = (step as NextActivity).session;
    expect(next.index, 1);
    expect(next.seed, 7);

    final end = next.advance(
      const ActivityResult(xp: 5, mistakes: 2),
      activityCount: 2,
    );
    final outcome = (end as LessonFinished).outcome;
    expect(outcome.xp, 15);
    expect(outcome.mistakes, 3);
  });

  test('a one-activity lesson finishes at once', () {
    expect(
      const LessonSession(
        lesson: _key,
        seed: 1,
      ).advance(const ActivityResult(xp: 3), activityCount: 1),
      isA<LessonFinished>(),
    );
  });

  test('survives a JSON round trip', () {
    const session = LessonSession(
      lesson: _key,
      seed: 1794593081460593,
      index: 2,
      xp: 25,
      mistakes: 1,
    );
    final back = LessonSession.fromJson(session.toJson());
    expect(
      (back.lesson, back.seed, back.index, back.xp, back.mistakes),
      (_key, session.seed, 2, 25, 1),
    );
  });
}
