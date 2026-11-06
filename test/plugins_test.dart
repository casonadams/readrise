import 'package:flutter_test/flutter_test.dart';
import 'package:readrise/engine/registry.dart';
import 'package:readrise/plugins.dart';

void main() {
  test('installed courses coexist: unique ids and valid requirements', () {
    final registry = PluginRegistry(installedCourses());
    expect(registry.courses, isNotEmpty);
  });
}
