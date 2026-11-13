import 'dart:math';

import 'package:flutter/material.dart';
import 'package:readrise/engine/registry.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

class FakeSpeaker implements Speaker {
  final List<String> spoken = [];

  @override
  Future<void> speak(String text) async => spoken.add(text);
}

/// Shows a button labelled [label] that records [answers], then completes
/// with [result].
class FakeActivity implements ActivityPlugin {
  const FakeActivity(
    this.label, [
    this.result = const ActivityResult(),
    this.answers = const [],
  ]);

  final String label;
  final ActivityResult result;
  final List<Answer> answers;

  @override
  Widget build(BuildContext context, ActivityHost host) => Center(
    child: FilledButton(
      onPressed: () {
        answers.forEach(host.record);
        host.complete(result);
      },
      child: Text(label),
    ),
  );
}

/// A [FakeActivity] whose label, once shuffled, ends with the first number
/// the attempt's random gave it, so tests can see which arrangement ran.
class FakeShufflingActivity extends FakeActivity implements Randomizable {
  const FakeShufflingActivity(super.label, [super.result]);

  @override
  ActivityPlugin shuffled(Random random) =>
      FakeActivity('$label ${random.nextInt(1000)}', result);
}

/// A [FakeActivity] that reviews [reviewable] items, [reviewSize] at a
/// time; when the engine picks items it shows "reviewing" and their ids.
class FakeReview extends FakeActivity implements Review {
  const FakeReview(
    super.label, {
    required this.reviewable,
    this.reviewSize = 1,
  });

  @override
  final List<ItemId> reviewable;

  @override
  final int reviewSize;

  @override
  ActivityPlugin reviewing(List<ItemId> items) =>
      FakeActivity('reviewing ${items.map((i) => i.value).join(' ')}');
}

class FakeLesson implements LessonPlugin {
  FakeLesson(String id, {List<ActivityPlugin>? activities})
    : id = LessonId(id),
      activities = activities ?? [FakeActivity('finish $id')];

  @override
  final LessonId id;

  @override
  String get title => 'L$id';

  @override
  final List<ActivityPlugin> activities;
}

class FakeCourse implements CoursePlugin {
  FakeCourse(
    String id,
    List<String> lessonIds, {
    List<String> requires = const [],
    this.subject = Subject.reading,
  }) : id = CourseId(id),
       requires = [for (final r in requires) CourseId(r)],
       lessons = [for (final l in lessonIds) FakeLesson(l)];

  FakeCourse.of(
    String id,
    this.lessons, {
    List<String> requires = const [],
    this.subject = Subject.reading,
  }) : id = CourseId(id),
       requires = [for (final r in requires) CourseId(r)];

  @override
  final CourseId id;

  @override
  String get title => 'Course $id';

  @override
  Grade get grade => Grade.preK;

  @override
  final Subject subject;

  @override
  final List<CourseId> requires;

  @override
  final List<LessonPlugin> lessons;
}

/// Course "a": lessons 1-3. Course "b" (requires "a"): lessons 4-5.
PluginRegistry buildRegistry() => PluginRegistry([
  FakeCourse('a', ['1', '2', '3']),
  FakeCourse('b', ['4', '5'], requires: ['a']),
]);

/// Reading "r1" (lessons a, b) then "r2" (lesson c, needs r1), plus Science
/// "s1" (lessons x, y). Lesson titles are "La", "Lb", ...
PluginRegistry buildSubjectRegistry() => PluginRegistry([
  FakeCourse('r1', ['a', 'b']),
  FakeCourse('r2', ['c'], requires: ['r1']),
  FakeCourse('s1', ['x', 'y'], subject: Subject.science),
]);
