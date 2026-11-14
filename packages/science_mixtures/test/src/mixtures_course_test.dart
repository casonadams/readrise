import 'package:flutter_test/flutter_test.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';
import 'package:readrise_testing/readrise_testing.dart';
import 'package:science_mixtures/science_mixtures.dart';

void main() {
  final course = MixturesCourse();

  test('opens after States of Matter, lessons in teaching order', () {
    expect(course.requires, [const CourseId('states-of-matter')]);
    expect(course.lessons.map((l) => l.id.value), [
      'dissolving',
      'melting-or-dissolving',
      'mass',
      'how-much',
    ]);
  });

  courseContentContract(course);
}
