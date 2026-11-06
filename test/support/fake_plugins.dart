import 'package:flutter/material.dart';
import 'package:readrise/engine/registry.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

class FakeSpeaker implements Speaker {
  final List<String> spoken = [];

  @override
  Future<void> speak(String text) async => spoken.add(text);
}

/// Shows a button labelled [label] that completes with [result].
class FakeActivity implements ActivityPlugin {
  const FakeActivity(this.label, [this.result = const ActivityResult()]);

  final String label;
  final ActivityResult result;

  @override
  Widget build(BuildContext context, ActivityHost host) => Center(
    child: FilledButton(
      onPressed: () => host.complete(result),
      child: Text(label),
    ),
  );
}

class FakeLesson implements LessonPlugin {
  FakeLesson(this.id, {List<ActivityPlugin>? activities})
    : activities = activities ?? [FakeActivity('finish $id')];

  @override
  final String id;

  @override
  String get title => 'L$id';

  @override
  final List<ActivityPlugin> activities;
}

class FakeCourse implements CoursePlugin {
  FakeCourse(
    this.id,
    List<String> lessonIds, {
    this.requires = const [],
    this.subject = Subject.reading,
  }) : lessons = [for (final l in lessonIds) FakeLesson(l)];

  FakeCourse.of(
    this.id,
    this.lessons, {
    this.requires = const [],
    this.subject = Subject.reading,
  });

  @override
  final String id;

  @override
  String get title => 'Course $id';

  @override
  Grade get grade => Grade.preK;

  @override
  final Subject subject;

  @override
  final List<String> requires;

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
