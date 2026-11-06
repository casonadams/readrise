import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/progress_store.dart';
import '../data/speaker.dart';
import '../engine/progress.dart';
import '../engine/registry.dart';

final registryProvider = Provider<PluginRegistry>(
  (ref) => throw UnimplementedError('override in main'),
);

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('override in main'),
);

final speakerProvider = Provider<Speaker>((ref) => TtsSpeaker());

final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final progressProvider = NotifierProvider<ProgressNotifier, Progress>(
  ProgressNotifier.new,
);

class ProgressNotifier extends Notifier<Progress> {
  late final ProgressStore _store = ProgressStore(
    ref.read(sharedPreferencesProvider),
  );

  @override
  Progress build() => _store.load();

  Future<void> recordLesson({
    required CoursePlugin course,
    required LessonPlugin lesson,
    required LessonOutcome outcome,
  }) {
    state = state.recordLesson(
      course: course,
      lesson: lesson,
      outcome: outcome,
      today: ref.read(clockProvider)(),
    );
    return _store.save(state);
  }
}
