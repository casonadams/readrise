import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/progress_store.dart';
import '../data/speaker.dart';
import '../domain/curriculum.dart';
import '../domain/progress.dart';

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
    required Skill skill,
    required int stars,
    required int xp,
  }) {
    state = state.recordLesson(
      skill: skill,
      earnedStars: stars,
      earnedXp: xp,
      today: ref.read(clockProvider)(),
    );
    return _store.save(state);
  }
}
