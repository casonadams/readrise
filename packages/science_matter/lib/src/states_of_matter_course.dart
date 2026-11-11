import 'package:readrise_plugin_api/readrise_plugin_api.dart';

import 'lessons/changes_lesson.dart';
import 'lessons/heat_lesson.dart';
import 'lessons/matter_lesson.dart';
import 'lessons/states_lesson.dart';

/// Matter, particles, states, heat and changes of state (NGSS MS-PS1-1, -4, -5).
class StatesOfMatterCourse implements CoursePlugin {
  StatesOfMatterCourse();

  @override
  String get id => 'states-of-matter';

  @override
  String get title => 'States of Matter';

  @override
  Grade get grade => Grade.grade6;

  @override
  Subject get subject => Subject.science;

  @override
  List<String> get requires => const [];

  @override
  final List<LessonPlugin> lessons = [
    matterLesson,
    statesLesson,
    heatLesson,
    changesLesson,
  ];
}
