import 'dart:math';

import 'package:readrise_plugin_api/readrise_plugin_api.dart';

/// The activities for one attempt at [lesson], in the lesson's order. Each
/// one that is [Randomizable] is arranged by [random], so every attempt
/// gets a new arrangement; the others are used as they are.
List<ActivityPlugin> attemptActivities(LessonPlugin lesson, Random random) => [
  for (final activity in lesson.activities)
    switch (activity) {
      final Randomizable varies => varies.shuffled(random),
      _ => activity,
    },
];
