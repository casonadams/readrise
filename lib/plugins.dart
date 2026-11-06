import 'package:phonics_alphabet/phonics_alphabet.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';
import 'package:science_matter/science_matter.dart';

/// Installed courses, in learning order. Add or remove a course here.
List<CoursePlugin> installedCourses() => [
  StatesOfMatterCourse(),
  ...AlphabetCourse.all(),
];
