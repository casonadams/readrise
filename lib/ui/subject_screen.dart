import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

import '../engine/progress.dart';
import '../engine/registry.dart';
import '../engine/subjects.dart';
import '../state/providers.dart';
import 'labels.dart';
import 'theme.dart';
import 'widgets/lesson_node.dart';
import 'widgets/page_frame.dart';
import 'widgets/stat_chip.dart';

/// The learning path for one subject: its courses, each a winding trail of
/// lessons, scrolled so the next lesson is in view.
class SubjectScreen extends ConsumerStatefulWidget {
  const SubjectScreen({required this.subjectId, super.key});

  final String subjectId;

  @override
  ConsumerState<SubjectScreen> createState() => _SubjectScreenState();
}

class _SubjectScreenState extends ConsumerState<SubjectScreen> {
  final GlobalKey _currentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _currentKey.currentContext;
      if (target != null) {
        Scrollable.ensureVisible(target, alignment: 0.4);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final registry = ref.watch(registryProvider);
    final progress = ref.watch(progressProvider);
    final streak = progress.streakOn(ref.watch(clockProvider)());
    final courses = [
      for (final c in registry.courses)
        if (c.subject.id == widget.subjectId) c,
    ];
    final subject = courses.first.subject;
    final current = nextUp(registry, progress, subjectId: subject.id);
    return Theme(
      data: subjectTheme(subject),
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('${subject.emoji} ${subject.title}'),
            actions: [
              StatChip(
                emoji: '\u{1F525}',
                value: streak,
                label: 'day streak',
                highlight: streak > 0,
              ),
              const SizedBox(width: 6),
              StatChip(emoji: '\u2B50', value: progress.xp, label: 'XP'),
              const SizedBox(width: 12),
            ],
          ),
          body: PageFrame(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 48),
              children: [
                for (final course in courses)
                  _CourseSection(
                    registry: registry,
                    course: course,
                    progress: progress,
                    current: current,
                    currentKey: _currentKey,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CourseSection extends StatelessWidget {
  const _CourseSection({
    required this.registry,
    required this.course,
    required this.progress,
    required this.current,
    required this.currentKey,
  });

  final PluginRegistry registry;
  final CoursePlugin course;
  final Progress progress;
  final LessonRef? current;
  final GlobalKey currentKey;

  String _lockReason(LessonPlugin lesson) {
    if (!progress.isCourseUnlocked(registry, course)) {
      final needed = course.requires
          .map((id) => registry.courseById(id).title)
          .join(' and ');
      return 'Finish $needed to unlock this unit.';
    }
    final i = course.lessons.indexOf(lesson);
    return 'Finish ${course.lessons[i - 1].title} first.';
  }

  @override
  Widget build(BuildContext context) {
    final open = progress.isCourseUnlocked(registry, course);
    return Column(
      children: [
        _Banner(course: course, open: open, registry: registry),
        const SizedBox(height: 8),
        for (var i = 0; i < course.lessons.length; i++)
          _node(context, course.lessons[i], i),
      ],
    );
  }

  Widget _node(BuildContext context, LessonPlugin lesson, int index) {
    final stars = progress.starsFor(course, lesson);
    final unlocked = progress.isLessonUnlocked(registry, course, lesson);
    final isCurrent =
        current != null &&
        current!.course == course &&
        current!.lesson == lesson;
    final state = !unlocked
        ? NodeState.locked
        : stars > 0
        ? NodeState.done
        : NodeState.current;
    return Align(
      key: isCurrent ? currentKey : null,
      alignment: Alignment(sin(index * 1.1) * 0.55, 0),
      child: LessonNode(
        title: lesson.title,
        state: state,
        stars: stars,
        onTap: () {
          if (unlocked) {
            context.push('/lesson/${course.id}/${lesson.id}');
            return;
          }
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text(_lockReason(lesson)),
              ),
            );
        },
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.course,
    required this.open,
    required this.registry,
  });

  final CoursePlugin course;
  final bool open;
  final PluginRegistry registry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final background = open ? scheme.primary : scheme.surfaceContainerHighest;
    final foreground = open ? scheme.onPrimary : scheme.onSurfaceVariant;
    return Semantics(
      container: true,
      header: true,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gradeLabel(course.grade).toUpperCase(),
                    style: text.labelMedium?.copyWith(
                      color: foreground.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    course.title,
                    style: text.titleLarge?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (!open)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Finish ${course.requires.map((id) => registry.courseById(id).title).join(' and ')} first',
                        style: text.bodyMedium?.copyWith(color: foreground),
                      ),
                    ),
                ],
              ),
            ),
            if (!open) Icon(Icons.lock_rounded, color: foreground),
          ],
        ),
      ),
    );
  }
}
