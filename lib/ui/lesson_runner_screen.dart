import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

import '../engine/progress.dart';
import '../state/providers.dart';

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
    await ref
        .read(progressProvider.notifier)
        .recordLesson(course: _course, lesson: _lesson, outcome: outcome);
  }

  @override
  Widget build(BuildContext context) {
    final outcome = _outcome;
    if (outcome != null) return _Result(outcome: outcome);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Leave lesson',
          onPressed: context.pop,
        ),
      ),
      body: _ActivityHost(
        key: ValueKey(_index),
        activity: _lesson.activities[_index],
        onDone: _onActivityDone,
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

class _Result extends StatelessWidget {
  const _Result({required this.outcome});

  final LessonOutcome outcome;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            [
              for (var s = 1; s <= 3; s++)
                s <= outcome.stars ? '\u2B50' : '\u2606',
            ].join(),
            style: const TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 16),
          Text(
            '+${outcome.xp} XP',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 32),
          FilledButton(onPressed: context.pop, child: const Text('Continue')),
        ],
      ),
    ),
  );
}
