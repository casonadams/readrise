import 'package:readrise_plugin_api/readrise_plugin_api.dart';
import 'package:science_kit/science_kit.dart';

import 'lessons/dissolving_lesson.dart';
import 'lessons/how_much_lesson.dart';
import 'lessons/mass_lesson.dart';
import 'lessons/melt_or_dissolve_lesson.dart';

/// Dissolving, solutions and conservation of mass when mixing
/// (NGSS 5-PS1-2, 5-PS1-4, MS-PS1-2).
class MixturesCourse implements CoursePlugin, Validated {
  MixturesCourse();

  @override
  CourseId get id => const CourseId('mixtures-and-solutions');

  @override
  String get title => 'Mixtures and Solutions';

  @override
  Grade get grade => Grade.grade6;

  @override
  Subject get subject => scienceSubject;

  @override
  List<CourseId> get requires => const [CourseId('states-of-matter')];

  @override
  final List<ScienceLesson> lessons = [
    dissolvingLesson,
    meltOrDissolveLesson,
    massLesson,
    howMuchLesson,
  ];

  @override
  void validate() => checkWarmUps(lessons);
}
