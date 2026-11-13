import 'dart:math';

import 'package:flutter/widgets.dart';

enum Grade {
  preK,
  kindergarten,
  grade1,
  grade2,
  grade3,
  grade4,
  grade5,
  grade6,
  grade7,
  grade8,
  grade9,
  grade10,
  grade11,
  grade12,
}

/// A school subject. Courses with the same subject are grouped under one card
/// and share its colour.
class Subject {
  const Subject({
    required this.id,
    required this.title,
    required this.emoji,
    required this.color,
  });

  static const reading = Subject(
    id: 'reading',
    title: 'Reading',
    emoji: '\u{1F4D6}',
    color: Color(0xFFFF7A2F),
  );

  static const science = Subject(
    id: 'science',
    title: 'Science',
    emoji: '\u{1F52C}',
    color: Color(0xFF1976D2),
  );

  final String id;
  final String title;
  final String emoji;
  final Color color;

  @override
  bool operator ==(Object other) =>
      other is Subject && other.id == id && other.title == title;

  @override
  int get hashCode => Object.hash(id, title);
}

/// Names a course. Learners' progress is stored under it, so it never
/// changes once shipped, and it may not contain "/".
extension type const CourseId(String value) {}

/// Names a lesson within its course. Learners' progress is stored under it,
/// so it never changes once shipped, and it may not contain "/".
extension type const LessonId(String value) {}

/// A course: an ordered set of lessons the engine shows as one learning path.
abstract interface class CoursePlugin {
  /// Unique across all registered courses.
  CourseId get id;
  String get title;
  Grade get grade;
  Subject get subject;

  /// Courses that must be complete before this one opens.
  List<CourseId> get requires;

  List<LessonPlugin> get lessons;
}

/// One node on the path: a sequence of activities the engine runs in order.
abstract interface class LessonPlugin {
  /// Unique within its course.
  LessonId get id;

  /// Label on the path node.
  String get title;

  List<ActivityPlugin> get activities;
}

/// One step inside a lesson: an introduction, a quiz, a game, ...
abstract interface class ActivityPlugin {
  /// Must call [ActivityHost.complete] exactly once when the learner finishes.
  Widget build(BuildContext context, ActivityHost host);
}

/// A course, lesson or activity that can check its own content. The engine
/// calls [validate] on each one at startup.
abstract interface class Validated {
  /// Throws an [ArgumentError] naming the first problem found.
  void validate();
}

/// An activity whose questions, choices or items can come in a different
/// order. The engine calls [shuffled] with a newly seeded [Random] for every
/// attempt, so a retake is arranged differently.
abstract interface class Randomizable {
  /// A copy arranged by [random]; the activity itself never changes.
  ActivityPlugin shuffled(Random random);
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
  /// Completes when the speech finishes or is interrupted by a newer call.
  Future<void> speak(String text);
}
