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
  FakeCourse(this.id, List<String> lessonIds, {this.requires = const []})
    : lessons = [for (final l in lessonIds) FakeLesson(l)];

  FakeCourse.of(this.id, this.lessons, {this.requires = const []});

  @override
  final String id;

  @override
  String get title => 'Course $id';

  @override
  Grade get grade => Grade.preK;

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
