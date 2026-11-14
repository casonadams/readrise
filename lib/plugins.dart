import 'package:phonics_alphabet/phonics_alphabet.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';
import 'package:science_matter/science_matter.dart';
import 'package:science_mixtures/science_mixtures.dart';

/// Subjects listed on the home screen but not open to learners yet, by id.
const comingSoonSubjects = {'reading'};

/// Installed courses, in learning order. Add or remove a course here.
List<CoursePlugin> installedCourses() => [
  StatesOfMatterCourse(),
  MixturesCourse(),
  ...AlphabetCourse.all(),
];
