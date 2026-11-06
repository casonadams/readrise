import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/curriculum.dart';
import '../state/providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 32),
        itemCount: curriculum.skills.length,
        itemBuilder: (context, i) {
          final skill = curriculum.skills[i];
          return Align(
            alignment: Alignment(((i % 4) - 1.5) * 0.35, 0),
            child: _SkillNode(
              skill: skill,
              stars: progress.starsFor(skill),
              unlocked: progress.isUnlocked(curriculum, skill),
            ),
          );
        },
      ),
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

class _SkillNode extends StatelessWidget {
  const _SkillNode({
    required this.skill,
    required this.stars,
    required this.unlocked,
  });

  final Skill skill;
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
            label: 'Lesson ${skill.title}',
            child: Material(
              color: unlocked ? scheme.primary : scheme.surfaceContainerHighest,
              shape: const CircleBorder(),
              elevation: unlocked ? 4 : 0,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: unlocked
                    ? () => context.push('/lesson/${skill.id}')
                    : null,
                child: SizedBox(
                  width: 112,
                  height: 112,
                  child: Center(
                    child: unlocked
                        ? Text(
                            skill.title,
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
            [
              for (var s = 1; s <= 3; s++) s <= stars ? '\u2B50' : '\u2606',
            ].join(),
            style: const TextStyle(fontSize: 24),
          ),
        ],
      ),
    );
  }
}
