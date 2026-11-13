import 'package:activity_kit/activity_kit.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

/// Questions on earlier lessons that open a lesson. [recalls] names the
/// lessons they draw on, which must come earlier in the course.
class WarmUp {
  const WarmUp({required this.recalls, required this.questions});

  final List<LessonId> recalls;
  final List<ChoiceQuestion> questions;
}

/// A science lesson whose activities follow the lesson arc in AGENTS.md:
/// warm-up, predict, explain, practise, check, "Who's right?".
class ScienceLesson implements LessonPlugin {
  ScienceLesson({
    required this.id,
    required this.title,
    required PredictActivity predict,
    required List<ExplainerActivity> explain,
    required List<ActivityPlugin> practise,
    required List<ChoiceQuestion> check,
    required WhoIsRightActivity debate,
    this.warmUp,
  }) : activities = [
         if (warmUp != null)
           ChoiceQuizActivity(
             kind: ActivityKind.warmUp,
             questions: warmUp.questions,
           ),
         predict,
         ...explain,
         ...practise,
         ChoiceQuizActivity(questions: check),
         debate,
       ] {
    if (explain.isEmpty || practise.isEmpty) {
      throw ArgumentError('lesson $id needs an explainer and a practice');
    }
  }

  @override
  final LessonId id;

  @override
  final String title;

  final WarmUp? warmUp;

  @override
  final List<ActivityPlugin> activities;
}

/// Throws unless only the first lesson skips the warm-up and every warm-up
/// recalls only lessons before its own.
void checkWarmUps(List<ScienceLesson> lessons) {
  for (final (i, lesson) in lessons.indexed) {
    final warmUp = lesson.warmUp;
    if ((i == 0) != (warmUp == null)) {
      throw ArgumentError(
        i == 0
            ? 'lesson ${lesson.id} is first, so it has no warm-up'
            : 'lesson ${lesson.id} needs a warm-up',
      );
    }
    final earlier = {for (final l in lessons.take(i)) l.id};
    for (final recalled in warmUp?.recalls ?? const <LessonId>[]) {
      if (!earlier.contains(recalled)) {
        throw ArgumentError(
          'lesson ${lesson.id} warms up on $recalled, which is not earlier',
        );
      }
    }
  }
}
