import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readrise/app.dart';
import 'package:readrise/data/progress_store.dart';
import 'package:readrise/engine/progress.dart';
import 'package:readrise/engine/registry.dart';
import 'package:readrise/state/providers.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_plugins.dart';

final today = DateTime(2026, 3, 8);

/// A phone-sized screen with reduced motion (so pumpAndSettle can finish)
/// and the given saved [progress].
Future<ProviderContainer> pumpApp(
  WidgetTester tester,
  PluginRegistry registry, {
  Progress progress = const Progress(),
  FakeSpeaker? speaker,
  Set<String> closedSubjects = const {},
  DateTime Function()? clock,
}) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  tester.view.physicalSize = const Size(1260, 2700);
  tester.view.devicePixelRatio = 3;
  addTearDown(() {
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
    tester.view.reset();
  });
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await ProgressStore(prefs).save(progress);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        registryProvider.overrideWithValue(registry),
        speakerProvider.overrideWithValue(speaker ?? FakeSpeaker()),
        clockProvider.overrideWithValue(clock ?? () => today),
        closedSubjectsProvider.overrideWithValue(closedSubjects),
      ],
      child: const ReadriseApp(),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
}

/// Progress with the lessons named "course/lesson" finished (3 stars unless
/// [mistakes] is set).
Progress finished(
  PluginRegistry registry,
  List<String> keys, {
  int mistakes = 0,
  int xp = 0,
}) {
  var p = const Progress();
  for (final key in keys) {
    final [course, lesson] = key.split('/');
    p = p.recordLesson(
      course: registry.courseById(CourseId(course)),
      lesson: registry.lessonById(CourseId(course), LessonId(lesson)),
      outcome: LessonOutcome(xp: xp, mistakes: mistakes),
      today: today,
    );
  }
  return p;
}
