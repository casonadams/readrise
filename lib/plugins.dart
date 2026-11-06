import 'package:phonics_alphabet/phonics_alphabet.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

/// Installed courses, in learning order. Add or remove a course here.
List<CoursePlugin> installedCourses() => [
  AlphabetCourse.set1(),
  AlphabetCourse.set2(),
];
