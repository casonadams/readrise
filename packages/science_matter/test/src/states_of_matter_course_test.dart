@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:readrise_testing/readrise_testing.dart';
import 'package:science_matter/science_matter.dart';

void main() {
  final course = StatesOfMatterCourse();

  test('is open from the start and ordered matter, states, heat, changes, '
      'evaporation', () {
    expect(course.requires, isEmpty);
    expect(course.lessons.map((l) => l.id.value), [
      'matter',
      'states',
      'heat',
      'changes',
      'evaporation',
    ]);
  });

  courseContentContract(course);
}
