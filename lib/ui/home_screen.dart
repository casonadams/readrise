import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../engine/subjects.dart';
import '../state/providers.dart';
import 'theme.dart';
import 'widgets/page_frame.dart';
import 'widgets/stat_chip.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registry = ref.watch(registryProvider);
    final progress = ref.watch(progressProvider);
    final streak = progress.streakOn(ref.watch(clockProvider)());
    final closed = ref.watch(closedSubjectsProvider);
    final target = continueTarget(registry, progress, closed: closed);
    final summaries = summarizeSubjects(registry, progress, closed: closed);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: PageFrame(
          maxWidth: 720,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Readrise',
                      style: text.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  StatChip(
                    emoji: '\u{1F525}',
                    value: streak,
                    label: 'day streak',
                    highlight: streak > 0,
                  ),
                  const SizedBox(width: 8),
                  StatChip(emoji: '\u2B50', value: progress.xp, label: 'XP'),
                ],
              ),
              const SizedBox(height: 24),
              if (target != null)
                _ContinueCard(
                  target: target,
                  started: progress.lastLesson != null,
                )
              else
                const _AllDoneCard(),
              const SizedBox(height: 28),
              Text('Pick a subject', style: text.titleLarge),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, box) {
                  final columns = box.maxWidth >= 560 ? 2 : 1;
                  final width = (box.maxWidth - 16 * (columns - 1)) / columns;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      for (final s in summaries)
                        SizedBox(
                          width: width,
                          child: _SubjectCard(summary: s),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.target, required this.started});

  final LessonRef target;
  final bool started;

  @override
  Widget build(BuildContext context) {
    final subject = target.course.subject;
    final text = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      button: true,
      label:
          '${started ? 'Continue' : 'Start learning'}: ${target.lesson.title}, '
          '${target.course.title}',
      excludeSemantics: true,
      child: Material(
        color: subject.color,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () =>
              context.push('/lesson/${target.course.id}/${target.lesson.id}'),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    subject.emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (started ? 'Continue' : 'Start learning').toUpperCase(),
                        style: text.labelMedium?.copyWith(
                          color: onColor(subject.color).withValues(alpha: 0.8),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        target.lesson.title,
                        style: text.headlineSmall?.copyWith(
                          color: onColor(subject.color),
                        ),
                      ),
                      Text(
                        target.course.title,
                        style: text.bodyMedium?.copyWith(
                          color: onColor(subject.color),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.play_circle_fill_rounded,
                  size: 48,
                  color: onColor(subject.color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AllDoneCard extends StatelessWidget {
  const _AllDoneCard();

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const Text('\u{1F389}', style: TextStyle(fontSize: 40)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'All caught up! Replay any lesson to earn more stars.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    ),
  );
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.summary});

  final SubjectSummary summary;

  @override
  Widget build(BuildContext context) {
    final subject = summary.subject;
    final text = Theme.of(context).textTheme;
    final status = !summary.open
        ? 'Coming soon'
        : summary.finished
        ? 'All ${summary.lessonsTotal} lessons done'
        : summary.started
        ? '${summary.lessonsDone} of ${summary.lessonsTotal} lessons'
        : '${summary.lessonsTotal} lessons';
    return Semantics(
      container: true,
      button: true,
      enabled: summary.open,
      label: '${subject.title}, $status',
      excludeSemantics: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Opacity(
          opacity: summary.open ? 1 : 0.5,
          child: InkWell(
            onTap: summary.open
                ? () => context.push('/subject/${subject.id}')
                : null,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: subject.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      subject.emoji,
                      style: const TextStyle(fontSize: 34),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(subject.title, style: text.titleLarge),
                        const SizedBox(height: 2),
                        Text(status, style: text.bodyMedium),
                        if (summary.open) ...[
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: summary.fraction,
                              minHeight: 10,
                              color: subject.color,
                              backgroundColor: subject.color.withValues(
                                alpha: 0.15,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    summary.open
                        ? Icons.chevron_right_rounded
                        : Icons.lock_rounded,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
