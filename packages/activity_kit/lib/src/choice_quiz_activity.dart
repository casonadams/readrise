import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

import 'activity_header.dart';
import 'answer_panel.dart';
import 'content/choice.dart';
import 'content/question.dart';
import 'feedback_banner.dart';
import 'feedback_layout.dart';
import 'option_tile.dart';
import 'score.dart';
import 'shake.dart';
import 'step_dots.dart';

/// Multiple-choice questions with scaffolding. A wrong pick is crossed out,
/// counted as a mistake, and explained; the learner keeps trying. A question
/// with a [Reason] asks why once the answer is right. Settling a question
/// without a miss or a hint earns full credit, otherwise half.
class ChoiceQuizActivity implements ActivityPlugin, Validated, Randomizable {
  const ChoiceQuizActivity({
    required this.questions,
    this.kind = ActivityKind.check,
    this.maxXp = 20,
  });

  final List<ChoiceQuestion> questions;
  final ActivityKind kind;
  final int maxXp;

  @override
  Widget build(BuildContext context, ActivityHost host) =>
      _QuizView(activity: this, host: host);

  /// The questions in a new order, each with its choices shuffled.
  @override
  ChoiceQuizActivity shuffled(Random random) => ChoiceQuizActivity(
    questions: [
      for (final q in [...questions]..shuffle(random)) q.shuffled(random),
    ],
    kind: kind,
    maxXp: maxXp,
  );

  @override
  void validate() {
    for (final q in questions) {
      q.validate();
    }
  }
}

class _QuizView extends StatefulWidget {
  const _QuizView({required this.activity, required this.host});

  final ChoiceQuizActivity activity;
  final ActivityHost host;

  @override
  State<_QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<_QuizView> {
  int _index = 0;
  final List<int> _wrong = [];
  final List<int> _wrongReasons = [];
  final Map<String, int> _shakes = {};
  bool _hintShown = false;
  bool _answered = false;
  bool _reasoned = false;
  int _firstTry = 0;
  int _recovered = 0;
  int _mistakes = 0;

  List<ChoiceQuestion> get _questions => widget.activity.questions;
  ChoiceQuestion get _question => _questions[_index];
  bool get _settled => _answered && (_question.reason == null || _reasoned);

  void _showHint() => setState(() => _hintShown = true);

  void _score() => _wrong.isEmpty && _wrongReasons.isEmpty && !_hintShown
      ? _firstTry++
      : _recovered++;

  void _miss(String key) {
    HapticFeedback.lightImpact();
    _shakes[key] = (_shakes[key] ?? 0) + 1;
    _mistakes++;
  }

  void _pick(int option) {
    if (_answered || _wrong.contains(option)) return;
    setState(() {
      if (_question.choices[option] is Right) {
        HapticFeedback.selectionClick();
        _answered = true;
        if (_question.reason == null) _score();
        return;
      }
      _wrong.add(option);
      _miss('a$option');
      if (_wrong.length >= hintAfterMisses && _question.hint != null) {
        _hintShown = true;
      }
    });
  }

  void _pickReason(int option) {
    final reason = _question.reason!;
    if (_reasoned || _wrongReasons.contains(option)) return;
    setState(() {
      if (reason.choices[option] is Right) {
        HapticFeedback.selectionClick();
        _reasoned = true;
        _score();
        return;
      }
      _wrongReasons.add(option);
      _miss('r$option');
    });
  }

  void _next() {
    if (_index + 1 == _questions.length) {
      widget.host.complete(
        ActivityResult(
          xp: scoreXp(
            firstTry: _firstTry,
            recovered: _recovered,
            total: _questions.length,
            max: widget.activity.maxXp,
          ),
          mistakes: _mistakes,
        ),
      );
      return;
    }
    setState(() {
      _index++;
      _wrong.clear();
      _wrongReasons.clear();
      _hintShown = false;
      _answered = false;
      _reasoned = false;
    });
  }

  OptionState _answerState(int i) {
    if (_answered && _question.choices[i] is Right) {
      return OptionState.correct;
    }
    if (_wrong.contains(i)) return OptionState.wrong;
    return _answered ? OptionState.dimmed : OptionState.open;
  }

  OptionState _reasonState(int i) {
    if (_reasoned && _question.reason!.choices[i] is Right) {
      return OptionState.correct;
    }
    if (_wrongReasons.contains(i)) return OptionState.wrong;
    return _reasoned ? OptionState.dimmed : OptionState.open;
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
    child: FeedbackLayout(feedback: _feedback(), page: _page),
  );

  Widget? _feedback() {
    final q = _question;
    if (_settled) {
      return AnswerPanel(
        key: ValueKey('settled:$_index'),
        title: _wrong.isEmpty && _wrongReasons.isEmpty && !_hintShown
            ? 'Correct!'
            : 'You got it!',
        explanation: q.explanation,
        onContinue: _next,
      );
    }
    final reason = q.reason;
    final lastWrong = _wrong.lastOrNull;
    final lastWrongReason = _wrongReasons.lastOrNull;
    final banners = [
      if (!_answered && lastWrong != null)
        FeedbackBanner(
          kind: FeedbackKind.wrong,
          message: (q.choices[lastWrong] as Wrong).feedback,
        ),
      if (!_answered && _hintShown && q.hint != null)
        FeedbackBanner(
          kind: FeedbackKind.hint,
          title: 'Hint',
          message: q.hint!,
        ),
      if (_answered && reason != null && lastWrongReason != null)
        FeedbackBanner(
          kind: FeedbackKind.wrong,
          message: (reason.choices[lastWrongReason] as Wrong).feedback,
        ),
    ];
    if (banners.isEmpty) return null;
    return Column(
      key: ValueKey('$_index:$lastWrong:$_hintShown:$lastWrongReason'),
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, banner) in banners.indexed) ...[
          if (i > 0) const SizedBox(height: 8),
          banner,
        ],
      ],
    );
  }

  Widget _page(BuildContext context, double covered) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final q = _question;
    final reason = q.reason;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActivityHeader(
          kind: widget.activity.kind,
          trailing: Row(
            children: [
              Text(
                '${_index + 1} of ${_questions.length}',
                style: text.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 10),
              ExcludeSemantics(
                child: StepDots(count: _questions.length, current: _index),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topCenter,
              children: [...previous, ?current],
            ),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0.08, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: SingleChildScrollView(
              key: ValueKey(_index),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(q.prompt, style: text.titleLarge?.copyWith(height: 1.3)),
                  if (q.visual != null) ...[
                    const SizedBox(height: 16),
                    SizedBox(height: 180, child: q.visual!(context)),
                  ],
                  const SizedBox(height: 20),
                  for (var i = 0; i < q.choices.length; i++)
                    _tile(
                      key: 'a$i',
                      letter: String.fromCharCode(65 + i),
                      label: q.choices[i].text,
                      state: _answerState(i),
                      onTap: () => _pick(i),
                    ),
                  if (!_answered && !_hintShown && q.hint != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _showHint,
                        icon: const Icon(Icons.lightbulb_outline),
                        label: const Text('Need a hint?'),
                      ),
                    ),
                  if (_answered && reason != null) ...[
                    const SizedBox(height: 8),
                    _ReasonHeading(prompt: reason.prompt),
                    const SizedBox(height: 12),
                    for (var i = 0; i < reason.choices.length; i++)
                      _tile(
                        key: 'r$i',
                        letter: '${i + 1}',
                        label: reason.choices[i].text,
                        state: _reasonState(i),
                        onTap: () => _pickReason(i),
                      ),
                  ],
                  SizedBox(height: covered),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tile({
    required String key,
    required String letter,
    required String label,
    required OptionState state,
    required VoidCallback onTap,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Shake(
      trigger: _shakes[key] ?? 0,
      child: OptionTile(
        letter: letter,
        label: label,
        state: state,
        onTap: onTap,
      ),
    ),
  );
}

/// "Right! Now, why?" between the answer and its reason.
class _ReasonHeading extends StatelessWidget {
  const _ReasonHeading({required this.prompt});

  final String prompt;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutBack,
      builder: (context, t, child) =>
          Transform.scale(scale: 0.9 + 0.1 * t, child: child),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AnswerPanel.correctGreen,
          ),
          const SizedBox(width: 8),
          Text(
            'Right!',
            style: text.titleMedium?.copyWith(color: AnswerPanel.correctGreen),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(prompt, style: text.titleMedium)),
        ],
      ),
    );
  }
}
