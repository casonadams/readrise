import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

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

  final String courseId;
  final String lessonId;

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
  int _index = 0;
  int _xp = 0;
  int _mistakes = 0;
  LessonOutcome? _outcome;

  Future<void> _onActivityDone(ActivityResult result) async {
    _xp += result.xp;
    _mistakes += result.mistakes;
    if (_index + 1 < _lesson.activities.length) {
      setState(() => _index++);
      return;
    }
    final outcome = LessonOutcome(xp: _xp, mistakes: _mistakes);
    setState(() => _outcome = outcome);
    HapticFeedback.mediumImpact();
    await ref
        .read(progressProvider.notifier)
        .recordLesson(course: _course, lesson: _lesson, outcome: outcome);
  }

  Future<void> _confirmLeave() async {
    if (_index == 0) {
      context.pop();
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave this lesson?'),
        content: const Text('Your progress in this lesson will be lost.'),
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
                              total: _lesson.activities.length,
                              done: _index,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _ActivityHost(
                        key: ValueKey(_index),
                        activity: _lesson.activities[_index],
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
