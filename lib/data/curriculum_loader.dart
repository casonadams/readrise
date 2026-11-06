import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/curriculum.dart';

const _root = 'assets/curriculum';

Future<Curriculum> loadCurriculum(AssetBundle bundle) async {
  Future<Map<String, dynamic>> json(String path) async =>
      jsonDecode(await bundle.loadString(path)) as Map<String, dynamic>;

  final index = await json('$_root/index.json');
  final courseIds = (index['courses'] as List).cast<String>();
  return parseCurriculum(index, [
    for (final id in courseIds) await json('$_root/courses/$id.json'),
  ]);
}

/// Builds a [Curriculum]; [courseJson] must follow the order in [index].
/// Throws [FormatException] on malformed or inconsistent content.
Curriculum parseCurriculum(
  Map<String, dynamic> index,
  List<Map<String, dynamic>> courseJson,
) {
  final seenCourses = <String>{};
  final seenLessons = <String>{};
  final courses = <Course>[];
  for (final json in courseJson) {
    final id = json['id'] as String;
    if (!seenCourses.add(id)) throw FormatException('duplicate course $id');
    final requires = (json['requires'] as List? ?? []).cast<String>();
    for (final r in requires) {
      if (!seenCourses.contains(r) || r == id) {
        throw FormatException('course $id requires $r, which is not earlier');
      }
    }
    final lessons = [
      for (final l in json['lessons'] as List)
        _parseLesson(l as Map<String, dynamic>),
    ];
    for (final l in lessons) {
      if (!seenLessons.add(l.id))
        throw FormatException('duplicate lesson ${l.id}');
    }
    courses.add(
      Course(
        id: id,
        title: json['title'] as String,
        grade:
            Grade.values.asNameMap()[json['grade']] ??
            (throw FormatException(
              'course $id: unknown grade ${json['grade']}',
            )),
        requires: requires,
        lessons: lessons,
      ),
    );
  }
  final expected = (index['courses'] as List).cast<String>();
  if (!listEquals(expected, [for (final c in courses) c.id])) {
    throw FormatException('index lists $expected but courses differ');
  }
  return Curriculum(
    id: index['id'] as String,
    title: index['title'] as String,
    courses: courses,
  );
}

Lesson _parseLesson(Map<String, dynamic> json) => switch (json['type']) {
  'letter' => LetterLesson(
    id: json['id'] as String,
    letter: Letter(
      char: json['char'] as String,
      sound: json['sound'] as String,
      word: json['word'] as String,
      emoji: json['emoji'] as String,
    ),
  ),
  final other => throw FormatException(
    'lesson ${json['id']}: unknown type $other',
  ),
};
