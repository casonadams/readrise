import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:readrise/engine/registry.dart';
import 'package:readrise/plugins.dart';

void main() {
  test('installed courses coexist: unique ids and valid requirements', () {
    final registry = PluginRegistry(installedCourses());
    expect(registry.courses, isNotEmpty);
  });

  group('ids.lock', () {
    final locked = File('ids.lock')
        .readAsLinesSync()
        .where((line) => line.isNotEmpty && !line.startsWith('#'))
        .toSet();
    final installed = {
      for (final c in installedCourses())
        for (final l in c.lessons) '${c.id.value}/${l.id.value}',
    };

    test('no shipped id has been renamed or removed', () {
      expect(
        locked.difference(installed),
        isEmpty,
        reason: 'learners have progress stored under these ids',
      );
    });

    test('every installed id is locked', () {
      expect(
        installed.difference(locked),
        isEmpty,
        reason: 'add these ids to ids.lock',
      );
    });
  });
}
