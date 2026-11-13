import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

import '../engine/attempt.dart';
import '../engine/lesson_session.dart';
import '../engine/progress.dart';
import '../engine/subjects.dart';
import '../state/providers.dart';
import 'lesson_result.dart';
import 'theme.dart';
import 'widgets/page_frame.dart';

/// Runs a lesson's activities in order and scores the result.
class LessonRunnerScreen extends ConsumerStatefulWidget {
  const LessonRunnerScreen({
    required this.courseId,
    required this.lessonId,
    super.key,
  });

  final CourseId courseId;
  final LessonId lessonId;

  @override
  ConsumerState<LessonRunnerScreen> createState() => _LessonRunnerScreenState();
}

class _LessonRunnerScreenState extends ConsumerState<LessonRunnerScreen> {
  late final CoursePlugin _course = ref
      .read(registryProvider)
      .courseById(widget.courseId);
  late final LessonPlugin _lesson = ref
      .read(registryProvider)
      .lessonById(widget.courseId, widget.lessonId);

  late final LessonKey _key = lessonKey(_course, _lesson);
  late LessonSession _session = _resumeOrStart();
  late final List<ActivityPlugin> _activities = attemptActivities(
    _lesson,
    Random(_session.seed),
  );
  LessonOutcome? _outcome;

  /// Carries on a saved session for this lesson, or starts an attempt seeded
  /// from the clock so each new attempt is arranged differently.
  LessonSession _resumeOrStart() {
    final saved = ref.read(sessionStoreProvider).load();
    if (saved != null &&
        saved.lesson == _key &&
        saved.index < _lesson.activities.length) {
      return saved;
    }
    return LessonSession(
      lesson: _key,
      seed: ref.read(clockProvider)().microsecondsSinceEpoch,
    );
  }

  Future<void> _onActivityDone(ActivityResult result) async {
    final store = ref.read(sessionStoreProvider);
    switch (_session.advance(result, activityCount: _activities.length)) {
      case NextActivity(:final session):
        setState(() => _session = session);
        await store.save(session);
      case LessonFinished(:final outcome):
        setState(() => _outcome = outcome);
        HapticFeedback.mediumImpact();
        await store.clear(_key);
        await ref
            .read(progressProvider.notifier)
            .recordLesson(course: _course, lesson: _lesson, outcome: outcome);
    }
  }

  Future<void> _confirmLeave() async {
    if (_session.index == 0) {
      context.pop();
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave this lesson?'),
        content: const Text('Next time, you will start again at this step.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep going'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final outcome = _outcome;
    return Theme(
      data: subjectTheme(_course.subject),
      child: Builder(
        builder: (context) {
          if (outcome != null) return _result(outcome);
          return Scaffold(
            body: SafeArea(
              child: PageFrame(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 8, 20, 4),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            tooltip: 'Leave lesson',
                            onPressed: _confirmLeave,
                          ),
                          Expanded(
                            child: _Segments(
                              total: _activities.length,
                              done: _session.index,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _ActivityHost(
                        key: ValueKey(_session.index),
                        activity: _activities[_session.index],
                        onDone: _onActivityDone,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _result(LessonOutcome outcome) {
    final registry = ref.watch(registryProvider);
    final progress = ref.watch(progressProvider);
    final next = nextUp(registry, progress, subjectId: _course.subject.id);
    return LessonResult(
      outcome: outcome,
      streak: progress.streakOn(ref.watch(clockProvider)()),
      next: next,
      onBack: context.pop,
      onNext: () => context.pushReplacement(
        '/lesson/${next!.course.id}/${next.lesson.id}',
      ),
    );
  }
}

class _Segments extends StatelessWidget {
  const _Segments({required this.total, required this.done});

  final int total;
  final int done;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: 'Step ${done + 1} of $total',
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 0; i < total; i++)
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: i < done
                      ? scheme.primary
                      : i == done
                      ? scheme.primary.withValues(alpha: 0.35)
                      : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActivityHost extends ConsumerStatefulWidget {
  const _ActivityHost({
    required this.activity,
    required this.onDone,
    super.key,
  });

  final ActivityPlugin activity;
  final Future<void> Function(ActivityResult) onDone;

  @override
  ConsumerState<_ActivityHost> createState() => _ActivityHostState();
}

class _ActivityHostState extends ConsumerState<_ActivityHost>
    implements ActivityHost {
  bool _completed = false;

  @override
  Speaker get speaker => ref.read(speakerProvider);

  @override
  void complete(ActivityResult result) {
    if (_completed) return;
    _completed = true;
    widget.onDone(result);
  }

  @override
  Widget build(BuildContext context) => widget.activity.build(context, this);
}
