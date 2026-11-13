import 'package:readrise_plugin_api/readrise_plugin_api.dart';
import 'package:science_kit/science_kit.dart';

import 'lessons/changes_lesson.dart';
import 'lessons/evaporation_lesson.dart';
import 'lessons/heat_lesson.dart';
import 'lessons/matter_lesson.dart';
import 'lessons/states_lesson.dart';

/// Matter, particles, states, heat and changes of state (NGSS MS-PS1-1, -4, -5).
class StatesOfMatterCourse implements CoursePlugin, Validated {
  StatesOfMatterCourse();

  @override
  CourseId get id => const CourseId('states-of-matter');

  @override
  String get title => 'States of Matter';

  @override
  Grade get grade => Grade.grade6;

  @override
  Subject get subject => scienceSubject;

  @override
  List<CourseId> get requires => const [];

  @override
  final List<ScienceLesson> lessons = [
    matterLesson,
    statesLesson,
    heatLesson,
    changesLesson,
    evaporationLesson,
  ];

  @override
  void validate() => checkWarmUps(lessons);
}
