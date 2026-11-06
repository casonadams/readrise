import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../engine/progress.dart';

class ProgressStore {
  const ProgressStore(this._prefs);

  static const _key = 'progress.v1';
  final SharedPreferences _prefs;

  Progress load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return const Progress();
    return Progress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(Progress progress) =>
      _prefs.setString(_key, jsonEncode(progress.toJson()));
}
