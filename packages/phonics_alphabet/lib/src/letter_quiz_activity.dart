import 'dart:math';

import 'package:activity_kit/activity_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

import 'letter.dart';
import 'letter_text.dart';
import 'quiz_session.dart';

/// Hear a letter, or see a picture and hear its word, then pick the letter.
/// Wrong picks are crossed out in place and the question stays until it is
/// right.
class LetterQuizActivity implements ActivityPlugin, Randomizable {
  const LetterQuizActivity(this.newSession, {this.seed = 0});

  LetterQuizActivity.lesson({
    required Letter letter,
    required List<Letter> learned,
    required List<Letter> unseen,
  }) : seed = 0,
       newSession = ((random) => QuizSession.lesson(
         letter: letter,
         learned: learned,
         unseen: unseen,
         random: random,
       ));

  LetterQuizActivity.review({
    required List<Letter> letters,
    required List<Letter> known,
  }) : seed = 0,
       newSession = ((random) =>
           QuizSession.review(letters: letters, known: known, random: random));

  final QuizSession Function(Random random) newSession;

  /// Seeds the order of the questions and choices.
  final int seed;

  @override
  LetterQuizActivity shuffled(Random random) =>
      LetterQuizActivity(newSession, seed: random.nextSeed());

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

class _QuizViewState extends State<_QuizView>
    with SingleTickerProviderStateMixin {
  late final QuizSession _session = widget.activity.newSession(
    Random(widget.activity.seed),
  );
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  final Map<String, int> _shakes = {};
  Letter? _correctPick;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakPrompt());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _float.stop();
      _float.value = 0;
    } else if (!_float.isAnimating) {
      _float.repeat();
    }
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  void _speakPrompt() {
    final e = _session.current;
    widget.host.speaker.speak(
      e.kind == ExerciseKind.soundToLetter ? e.target.char : e.target.word,
    );
  }

  Future<void> _onPick(Letter choice) async {
    if (_correctPick != null || _session.isEliminated(choice)) return;
    if (!_session.answer(choice)) {
      HapticFeedback.lightImpact();
      setState(() => _shakes[choice.char] = (_shakes[choice.char] ?? 0) + 1);
      _speakPrompt();
      return;
    }
    HapticFeedback.selectionClick();
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
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: _session.progress,
            minHeight: 14,
            borderRadius: BorderRadius.circular(7),
          ),
          if (exercise != null) ...[
            const SizedBox(height: 20),
            Text(
              exercise.kind == ExerciseKind.soundToLetter
                  ? 'Tap the letter you hear'
                  : 'Which letter does it start with?',
              textAlign: TextAlign.center,
              style: text.titleMedium,
            ),
          ],
          Expanded(
            child: Center(
              child: exercise == null
                  ? const SizedBox.shrink()
                  : _Prompt(exercise: exercise, onTap: _speakPrompt),
            ),
          ),
          if (exercise != null)
            LayoutBuilder(
              builder: (context, box) {
                final n = exercise.options.length;
                final side = ((box.maxWidth - 12 * (n - 1)) / n).clamp(
                  76.0,
                  116.0,
                );
                return AnimatedBuilder(
                  animation: _float,
                  builder: (context, _) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < n; i++) ...[
                        if (i > 0) const SizedBox(width: 12),
                        Transform.translate(
                          offset: Offset(
                            0,
                            -7 * sin((_float.value + i / n) * 2 * pi),
                          ),
                          child: Shake(
                            trigger: _shakes[exercise.options[i].char] ?? 0,
                            child: _Balloon(
                              letter: exercise.options[i],
                              color:
                                  _balloonColors[(exercise.target.char
                                              .codeUnitAt(0) +
                                          i) %
                                      _balloonColors.length],
                              side: side,
                              crossedOut: _session.isEliminated(
                                exercise.options[i],
                              ),
                              popped: _correctPick == exercise.options[i],
                              onTap: () => _onPick(exercise.options[i]),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
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
      container: true,
      button: true,
      label: picture ? 'Hear the word again' : 'Hear the letter again',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              picture
                  ? Text(
                      exercise.target.emoji,
                      style: const TextStyle(fontSize: 120),
                    )
                  : Icon(
                      Icons.volume_up_rounded,
                      size: 120,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              if (picture)
                Icon(
                  Icons.volume_up_rounded,
                  size: 28,
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

const _balloonColors = [
  Color(0xFFE53935),
  Color(0xFF1E88E5),
  Color(0xFF2E7D32),
  Color(0xFF8E24AA),
  Color(0xFFD81B60),
  Color(0xFF00897B),
];

/// A balloon to pop. A right pick pops it; a wrong pick deflates it where it
/// floats so the remaining balloons keep their places.
class _Balloon extends StatelessWidget {
  const _Balloon({
    required this.letter,
    required this.color,
    required this.side,
    required this.crossedOut,
    required this.popped,
    required this.onTap,
  });

  final Letter letter;
  final Color color;
  final double side;
  final bool crossedOut;
  final bool popped;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final height = side * 1.15;
    return Semantics(
      container: true,
      button: true,
      enabled: !crossedOut,
      label: crossedOut
          ? 'Letter ${letter.char}, not this one'
          : 'Letter ${letter.char}',
      excludeSemantics: true,
      onTap: crossedOut ? null : onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: crossedOut ? null : onTap,
        child: SizedBox(
          width: side,
          height: height + 28,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              AnimatedScale(
                scale: popped
                    ? 1.5
                    : crossedOut
                    ? 0.8
                    : 1,
                alignment: Alignment.topCenter,
                duration: const Duration(milliseconds: 220),
                child: AnimatedOpacity(
                  opacity: popped
                      ? 0
                      : crossedOut
                      ? 0.3
                      : 1,
                  duration: const Duration(milliseconds: 260),
                  child: CustomPaint(
                    size: Size(side, height + 28),
                    painter: _BalloonPainter(color),
                    child: SizedBox(
                      width: side,
                      height: height,
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            side * 0.12,
                            0,
                            side * 0.12,
                            side * 0.08,
                          ),
                          child: LetterText(
                            letter.display,
                            style: letterTextStyle(44, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (popped)
                Positioned(
                  top: height * 0.25,
                  child: const Text(
                    '\u{1F4A5}',
                    style: TextStyle(fontSize: 56),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalloonPainter extends CustomPainter {
  const _BalloonPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final bodyHeight = size.height - 28;
    final body = Rect.fromLTWH(0, 0, w, bodyHeight);
    canvas.drawOval(
      body,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          radius: 0.95,
          colors: [Color.lerp(color, Colors.white, 0.35)!, color],
        ).createShader(body),
    );
    final knot = Path()
      ..moveTo(w * 0.5, bodyHeight - 2)
      ..lineTo(w * 0.44, bodyHeight + 7)
      ..lineTo(w * 0.56, bodyHeight + 7)
      ..close();
    canvas.drawPath(knot, Paint()..color = color);
    final string = Path()
      ..moveTo(w * 0.5, bodyHeight + 7)
      ..quadraticBezierTo(w * 0.62, bodyHeight + 14, w * 0.5, bodyHeight + 21)
      ..quadraticBezierTo(w * 0.4, bodyHeight + 25, w * 0.5, size.height);
    canvas.drawPath(
      string,
      Paint()
        ..color = Colors.black45
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_BalloonPainter old) => old.color != color;
}
