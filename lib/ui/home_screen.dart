import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:readrise_plugin_api/readrise_plugin_api.dart';

import '../engine/progress.dart';
import '../engine/registry.dart';
import '../state/providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registry = ref.watch(registryProvider);
    final progress = ref.watch(progressProvider);
    final streak = progress.streakOn(ref.watch(clockProvider)());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Readrise'),
        actions: [
          _Badge(emoji: '\u{1F525}', value: streak),
          _Badge(emoji: '\u2B50', value: progress.xp),
          const SizedBox(width: 12),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          for (final course in registry.courses)
            _CourseSection(
              registry: registry,
              course: course,
              progress: progress,
            ),
        ],
      ),
    );
  }
}

class _CourseSection extends StatelessWidget {
  const _CourseSection({
    required this.registry,
    required this.course,
    required this.progress,
  });

  final PluginRegistry registry;
  final CoursePlugin course;
  final Progress progress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final open = progress.isCourseUnlocked(registry, course);
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: open ? scheme.primaryContainer : scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            course.title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        for (var i = 0; i < course.lessons.length; i++)
          Align(
            alignment: Alignment(((i % 4) - 1.5) * 0.35, 0),
            child: _LessonNode(
              courseId: course.id,
              lesson: course.lessons[i],
              stars: progress.starsFor(course, course.lessons[i]),
              unlocked: progress.isLessonUnlocked(
                registry,
                course,
                course.lessons[i],
              ),
            ),
          ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.emoji, required this.value});

  final String emoji;
  final int value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 12),
    child: Text('$emoji $value', style: Theme.of(context).textTheme.titleLarge),
  );
}

class _LessonNode extends StatelessWidget {
  const _LessonNode({
    required this.courseId,
    required this.lesson,
    required this.stars,
    required this.unlocked,
  });

  final LessonPlugin lesson;
  final String courseId;
  final int stars;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: true,
            enabled: unlocked,
            label: 'Lesson ${lesson.title}',
            child: Material(
              color: unlocked ? scheme.primary : scheme.surfaceContainerHighest,
              shape: const CircleBorder(),
              elevation: unlocked ? 4 : 0,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: unlocked
                    ? () => context.push('/lesson/$courseId/${lesson.id}')
                    : null,
                child: SizedBox(
                  width: 112,
                  height: 112,
                  child: Center(
                    child: unlocked
                        ? Text(
                            lesson.title,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(color: scheme.onPrimary),
                          )
                        : Icon(Icons.lock, size: 40, color: scheme.outline),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            [for (var s = 1; s <= 3; s++) s <= stars ? '\u2B50' : '\u2606']
                .join(),
            style: const TextStyle(fontSize: 24),
          ),
        ],
      ),
    );
  }
}
