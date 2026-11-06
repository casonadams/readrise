import 'package:flutter/material.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

import 'letter.dart';
import 'quiz_session.dart';

/// Hear a sound or see a picture, then pick the matching letter.
class LetterQuizActivity implements ActivityPlugin {
  const LetterQuizActivity({
    required this.letter,
    required this.learned,
    required this.unseen,
  });

  final Letter letter;
  final List<Letter> learned;
  final List<Letter> unseen;

  @override
  Widget build(BuildContext context, ActivityHost host) =>
      _QuizView(activity: this, host: host);
}

class _QuizView extends StatefulWidget {
  const _QuizView({required this.activity, required this.host});

  final LetterQuizActivity activity;
  final ActivityHost host;

  @override
  State<_QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<_QuizView> {
  late final QuizSession _session = QuizSession(
    letter: widget.activity.letter,
    learned: widget.activity.learned,
    unseen: widget.activity.unseen,
  );
  Letter? _correctPick;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakPrompt());
  }

  void _speakPrompt() {
    final e = _session.current;
    widget.host.speaker.speak(
      e.kind == ExerciseKind.soundToLetter ? e.target.sound : e.target.word,
    );
  }

  Future<void> _onPick(Letter choice) async {
    if (_correctPick != null) return;
    if (!_session.answer(choice)) {
      setState(() {});
      _speakPrompt();
      return;
    }
    setState(() => _correctPick = choice);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    if (_session.isComplete) {
      widget.host.complete(
        ActivityResult(xp: _session.xp, mistakes: _session.mistakes),
      );
      return;
    }
    setState(() => _correctPick = null);
    _speakPrompt();
  }

  @override
  Widget build(BuildContext context) {
    final exercise = _session.isComplete ? null : _session.current;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: _session.progress,
            minHeight: 14,
            borderRadius: BorderRadius.circular(7),
          ),
          Expanded(
            child: Center(
              child: exercise == null
                  ? const SizedBox.shrink()
                  : _Prompt(exercise: exercise, onTap: _speakPrompt),
            ),
          ),
          if (exercise != null)
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                for (final option in _session.visibleOptions)
                  _OptionButton(
                    letter: option,
                    correct: _correctPick == null
                        ? null
                        : option == _correctPick,
                    onTap: () => _onPick(option),
                  ),
              ],
            ),
          const SizedBox(height: 24),
        ],
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
    required this.correct,
    required this.onTap,
  });

  final Letter letter;
  final bool? correct;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 104,
      height: 104,
      child: Semantics(
        button: true,
        label: 'Letter ${letter.char}',
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: correct == true
                ? Colors.green.shade300
                : scheme.secondaryContainer,
            foregroundColor: scheme.onSecondaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          onPressed: onTap,
          child: Text(letter.display, style: const TextStyle(fontSize: 40)),
        ),
      ),
    );
  }
}
