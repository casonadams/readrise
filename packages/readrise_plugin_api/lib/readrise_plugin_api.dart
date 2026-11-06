import 'package:flutter/widgets.dart';

enum Grade { preK, kindergarten, grade1 }

/// A course: an ordered set of lessons the engine shows as one learning path.
abstract interface class CoursePlugin {
  /// Stable and unique across all registered courses; progress is keyed by it.
  String get id;
  String get title;
  Grade get grade;

  /// Ids of courses that must be complete before this one opens.
  List<String> get requires;

  List<LessonPlugin> get lessons;
}

/// One node on the path: a sequence of activities the engine runs in order.
abstract interface class LessonPlugin {
  /// Stable and unique within its course.
  String get id;

  /// Label on the path node.
  String get title;

  List<ActivityPlugin> get activities;
}

/// One step inside a lesson: an introduction, a quiz, a game, ...
abstract interface class ActivityPlugin {
  /// Must call [ActivityHost.complete] exactly once when the learner finishes.
  Widget build(BuildContext context, ActivityHost host);
}

/// What the engine offers to the running activity.
abstract interface class ActivityHost {
  Speaker get speaker;
  void complete(ActivityResult result);
}

class ActivityResult {
  const ActivityResult({this.xp = 0, this.mistakes = 0});

  final int xp;
  final int mistakes;
}

abstract interface class Speaker {
  Future<void> speak(String text);
}
