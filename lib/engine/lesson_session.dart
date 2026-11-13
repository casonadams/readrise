import 'package:readrise_plugin_api/readrise_plugin_api.dart';

import 'progress.dart';

/// A lesson in progress: which attempt it is ([seed] arranges its
/// activities), which activity is next, and what it has earned so far.
/// Saved after every activity so a learner who leaves can carry on.
class LessonSession {
  const LessonSession({
    required this.lesson,
    required this.seed,
    this.index = 0,
    this.xp = 0,
    this.mistakes = 0,
  });

  factory LessonSession.fromJson(Map<String, dynamic> json) => LessonSession(
    lesson: decodeLessonKey(json['lesson'] as String),
    seed: json['seed'] as int,
    index: json['index'] as int,
    xp: json['xp'] as int,
    mistakes: json['mistakes'] as int,
  );

  final LessonKey lesson;
  final int seed;
  final int index;
  final int xp;
  final int mistakes;

  Map<String, dynamic> toJson() => {
    'lesson': encodeLessonKey(lesson),
    'seed': seed,
    'index': index,
    'xp': xp,
    'mistakes': mistakes,
  };

  /// Where the lesson goes once the current activity reports [result]:
  /// on to the next of its [activityCount] activities, or finished.
  SessionStep advance(ActivityResult result, {required int activityCount}) {
    final xp = this.xp + result.xp;
    final mistakes = this.mistakes + result.mistakes;
    if (index + 1 >= activityCount) {
      return LessonFinished(LessonOutcome(xp: xp, mistakes: mistakes));
    }
    return NextActivity(
      LessonSession(
        lesson: lesson,
        seed: seed,
        index: index + 1,
        xp: xp,
        mistakes: mistakes,
      ),
    );
  }
}

sealed class SessionStep {
  const SessionStep();
}

final class NextActivity extends SessionStep {
  const NextActivity(this.session);

  final LessonSession session;
}

final class LessonFinished extends SessionStep {
  const LessonFinished(this.outcome);

  final LessonOutcome outcome;
}
