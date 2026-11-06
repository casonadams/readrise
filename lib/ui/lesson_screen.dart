import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/curriculum.dart';
import '../domain/lesson_session.dart';
import '../state/providers.dart';

class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({required this.skill, super.key});

  final Skill skill;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  late final LessonSession _session = LessonSession(
    skill: widget.skill,
    pool: curriculum.lettersThrough(widget.skill),
  );
  Letter? _correctPick;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakPrompt());
  }

  void _speakPrompt() {
    final e = _session.current;
    ref
        .read(speakerProvider)
        .speak(
          e.kind == ExerciseKind.soundToLetter ? e.target.sound : e.target.word,
        );
  }

  Future<void> _onPick(Letter choice) async {
    if (_correctPick != null) return;
    final correct = _session.answer(choice);
    if (!correct) {
      setState(() {});
      _speakPrompt();
      return;
    }
    setState(() => _correctPick = choice);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _correctPick = null);
    if (_session.isComplete) {
      await ref
          .read(progressProvider.notifier)
          .recordLesson(
            skill: widget.skill,
            stars: _session.stars,
            xp: _session.xp,
          );
    } else {
      _speakPrompt();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_session.isComplete) return _Result(session: _session);
    final exercise = _session.current;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Leave lesson',
          onPressed: context.pop,
        ),
        title: LinearProgressIndicator(
          value: _session.progress,
          minHeight: 14,
          borderRadius: BorderRadius.circular(7),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: _Prompt(exercise: exercise, onTap: _speakPrompt),
              ),
            ),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                for (final option in _session.visibleOptions)
                  _OptionButton(
                    letter: option,
                    state: _correctPick == null ? null : option == _correctPick,
                    onTap: () => _onPick(option),
                  ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Prompt extends StatelessWidget {
  const _Prompt({required this.exercise, required this.onTap});

  final Exercise exercise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final picture = exercise.kind == ExerciseKind.pictureToLetter;
    return Semantics(
      button: true,
      label: 'Hear again',
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: picture
              ? Text(
                  exercise.target.emoji,
                  style: const TextStyle(fontSize: 120),
                )
              : Icon(
                  Icons.volume_up_rounded,
                  size: 120,
                  color: Theme.of(context).colorScheme.primary,
                ),
        ),
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.letter,
    required this.state,
    required this.onTap,
  });

  final Letter letter;
  final bool? state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (state) {
      true => Colors.green.shade300,
      _ => scheme.secondaryContainer,
    };
    return SizedBox(
      width: 104,
      height: 104,
      child: Semantics(
        button: true,
        label: 'Letter ${letter.char}',
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: color,
            foregroundColor: scheme.onSecondaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          onPressed: onTap,
          child: Text(
            '${letter.upper}${letter.char}',
            style: const TextStyle(fontSize: 40),
          ),
        ),
      ),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({required this.session});

  final LessonSession session;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            [
              for (var s = 1; s <= 3; s++)
                s <= session.stars ? '\u2B50' : '\u2606',
            ].join(),
            style: const TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 16),
          Text(
            '+${session.xp} XP',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 32),
          FilledButton(onPressed: context.pop, child: const Text('Continue')),
        ],
      ),
    ),
  );
}
