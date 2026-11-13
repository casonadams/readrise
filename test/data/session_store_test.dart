import 'package:flutter_test/flutter_test.dart';
import 'package:readrise/data/session_store.dart';
import 'package:readrise/engine/lesson_session.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _a1 = (course: CourseId('a'), lesson: LessonId('1'));
const _a2 = (course: CourseId('a'), lesson: LessonId('2'));

void main() {
  late SessionStore store;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = SessionStore(await SharedPreferences.getInstance());
  });

  test('keeps the last saved session', () async {
    expect(store.load(), isNull);
    await store.save(const LessonSession(lesson: _a1, seed: 3, index: 1));
    expect(store.load()?.index, 1);
  });

  test('finishing another lesson leaves this one in progress', () async {
    await store.save(const LessonSession(lesson: _a1, seed: 3, index: 1));
    await store.clear(_a2);
    expect(store.load()?.lesson, _a1);
    await store.clear(_a1);
    expect(store.load(), isNull);
  });
}
