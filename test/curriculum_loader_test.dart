import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readrise/data/curriculum_loader.dart';
import 'package:readrise/domain/curriculum.dart';

Map<String, dynamic> course(
  String id, {
  List<String> requires = const [],
  List<String> lessonIds = const ['x'],
  String grade = 'preK',
  String type = 'letter',
}) => {
  'id': id,
  'title': id,
  'grade': grade,
  'requires': requires,
  'lessons': [
    for (final l in lessonIds)
      {
        'id': l,
        'type': type,
        'char': 'x',
        'sound': 'x',
        'word': 'x',
        'emoji': 'x',
      },
  ],
};

Map<String, dynamic> index(List<String> ids) => {
  'id': 'c',
  'title': 'C',
  'courses': ids,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('shipped assets load into a consistent curriculum', () async {
    final c = await loadCurriculum(rootBundle);
    expect(c.courses.length, greaterThanOrEqualTo(2));
    final ids = c.lessons.map((l) => l.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
    expect(c.lessons.whereType<LetterLesson>(), isNotEmpty);
  });

  test('parses requires and lesson order', () {
    final c = parseCurriculum(index(['a', 'b']), [
      course('a', lessonIds: ['a1', 'a2']),
      course('b', requires: ['a'], lessonIds: ['b1']),
    ]);
    expect(c.courseById('b').requires, ['a']);
    expect(c.lessons.map((l) => l.id), ['a1', 'a2', 'b1']);
  });

  final invalid = <String, (List<String>, List<Map<String, dynamic>>)>{
    'duplicate lesson id across courses': (
      ['a', 'b'],
      [course('a'), course('b')],
    ),
    'requires a later course': (
      ['a', 'b'],
      [
        course('a', requires: ['b'], lessonIds: ['l1']),
        course('b', lessonIds: ['l2']),
      ],
    ),
    'unknown grade': (['a'], [course('a', grade: 'grade99')]),
    'unknown lesson type': (['a'], [course('a', type: 'dance')]),
    'index disagrees with course files': (['a', 'b'], [course('a')]),
  };
  invalid.forEach((name, input) {
    test('rejects $name', () {
      expect(
        () => parseCurriculum(index(input.$1), input.$2),
        throwsFormatException,
      );
    });
  });
}
