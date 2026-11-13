import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../engine/lesson_session.dart';
import '../engine/progress.dart';

/// The one lesson in progress, kept apart from [Progress] so its format can
/// change without touching learners' stars.
class SessionStore {
  const SessionStore(this._prefs);

  static const _key = 'session.v1';
  final SharedPreferences _prefs;

  LessonSession? load() => switch (_prefs.getString(_key)) {
    final String raw => LessonSession.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    ),
    null => null,
  };

  Future<void> save(LessonSession session) =>
      _prefs.setString(_key, jsonEncode(session.toJson()));

  /// Forgets the saved session if it belongs to [lesson].
  Future<void> clear(LessonKey lesson) async {
    if (load()?.lesson == lesson) await _prefs.remove(_key);
  }
}
