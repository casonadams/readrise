import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:readrise/engine/registry.dart';
import 'package:readrise/plugins.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

/// Tests that [file] lists exactly the shipped ids, so none is renamed or
/// removed: learners' saved data is stored under them.
void lockGroup(String file, Set<String> installed) {
  group(file, () {
    final locked = File(file)
        .readAsLinesSync()
        .where((line) => line.isNotEmpty && !line.startsWith('#'))
        .toSet();

    test('no shipped id has been renamed or removed', () {
      expect(
        locked.difference(installed),
        isEmpty,
        reason: 'learners have data stored under these ids',
      );
    });

    test('every installed id is locked', () {
      expect(
        installed.difference(locked),
        isEmpty,
        reason: 'add these ids to $file',
      );
    });
  });
}

void main() {
  final courses = installedCourses();

  test('installed courses coexist: unique ids and valid requirements', () {
    final registry = PluginRegistry(courses);
    expect(registry.courses, isNotEmpty);
  });

  lockGroup('ids.lock', {
    for (final c in courses)
      for (final l in c.lessons) '${c.id.value}/${l.id.value}',
  });
  lockGroup('items.lock', {
    for (final c in courses)
      for (final l in c.lessons)
        for (final a in l.activities)
          if (a case final HasItems answered)
            for (final i in answered.items) '${c.id.value}/${i.value}',
  });
}
