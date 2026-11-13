import 'package:flutter/painting.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:readrise/engine/registry.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

import '../support/fake_plugins.dart';

class _NoActivities extends FakeLesson {
  _NoActivities() : super('x', activities: const []);
}

void main() {
  test('keeps courses in the order given and looks them up by id', () {
    final registry = buildRegistry();
    expect(registry.courses.map((c) => c.id), ['a', 'b']);
    expect(
      registry.lessonById(const CourseId('b'), const LessonId('5')).id,
      '5',
    );
  });

  test('the same lesson id may appear in different courses', () {
    expect(
      () => PluginRegistry([
        FakeCourse('a', ['1']),
        FakeCourse('b', ['1']),
      ]),
      returnsNormally,
    );
  });

  test('unknown ids are rejected', () {
    final registry = buildRegistry();
    expect(
      () => registry.courseById(const CourseId('nope')),
      throwsArgumentError,
    );
    expect(
      () => registry.lessonById(const CourseId('a'), const LessonId('nope')),
      throwsArgumentError,
    );
  });

  test('one subject id with two different titles is rejected', () {
    const clash = Subject(
      id: 'reading',
      title: 'Literacy',
      emoji: 'x',
      color: Color(0xFF000000),
    );
    expect(
      () => PluginRegistry([
        FakeCourse('a', ['1']),
        FakeCourse('b', ['2'], subject: clash),
      ]),
      throwsArgumentError,
    );
  });

  test('courses may share a subject', () {
    expect(
      () => PluginRegistry([
        FakeCourse('a', ['1']),
        FakeCourse('b', ['2']),
      ]),
      returnsNormally,
    );
  });

  final invalid = <String, List<CoursePlugin> Function()>{
    'duplicate course id': () => [
      FakeCourse('a', ['1']),
      FakeCourse('a', ['2']),
    ],
    'duplicate lesson id in one course': () => [
      FakeCourse('a', ['1', '1']),
    ],
    'requirement installed later': () => [
      FakeCourse('a', ['1'], requires: ['b']),
      FakeCourse('b', ['2']),
    ],
    'requirement not installed': () => [
      FakeCourse('a', ['1'], requires: ['zz']),
    ],
    'course requiring itself': () => [
      FakeCourse('a', ['1'], requires: ['a']),
    ],
    'course without lessons': () => [FakeCourse('a', [])],
    'lesson without activities': () => [
      FakeCourse.of('a', [_NoActivities()]),
    ],
    'course id containing "/"': () => [
      FakeCourse('a/b', ['1']),
    ],
    'lesson id containing "/"': () => [
      FakeCourse('a', ['1/2']),
    ],
    'empty lesson id': () => [
      FakeCourse('a', ['']),
    ],
  };
  invalid.forEach((name, build) {
    test('rejects $name', () {
      expect(() => PluginRegistry(build()), throwsArgumentError);
    });
  });
}
