import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

import 'score.dart';
import 'shake.dart';

class ChoiceQuestion {
  const ChoiceQuestion({
    required this.prompt,
    required this.options,
    required this.answer,
    required this.explanation,
    this.visual,
  });

  final String prompt;
  final List<String> options;

  /// Index into [options] of the correct choice.
  final int answer;

  /// Shown after the correct choice; say why it is right.
  final String explanation;
  final WidgetBuilder? visual;
}

/// Multiple-choice questions. A wrong pick is removed and counted as a
/// mistake; the learner keeps trying, then reads the explanation.
class ChoiceQuizActivity implements ActivityPlugin {
  const ChoiceQuizActivity({required this.questions, this.maxXp = 20});

  final List<ChoiceQuestion> questions;
  final int maxXp;

  @override
  Widget build(BuildContext context, ActivityHost host) =>
      _QuizView(activity: this, host: host);
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
  final Set<int> _wrong = {};
  final Map<int, int> _shakes = {};
  bool _solved = false;
  int _firstTry = 0;
  int _recovered = 0;
  int _mistakes = 0;

  List<ChoiceQuestion> get _questions => widget.activity.questions;
  ChoiceQuestion get _question => _questions[_index];

  void _pick(int option) {
    if (_solved || _wrong.contains(option)) return;
    if (option == _question.answer) {
      HapticFeedback.selectionClick();
    } else {
      HapticFeedback.lightImpact();
    }
    setState(() {
      if (option == _question.answer) {
        _solved = true;
        _wrong.isEmpty ? _firstTry++ : _recovered++;
      } else {
        _wrong.add(option);
        _shakes[option] = (_shakes[option] ?? 0) + 1;
        _mistakes++;
      }
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
      _solved = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final q = _question;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            value: _index / _questions.length,
            minHeight: 12,
            borderRadius: BorderRadius.circular(6),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(q.prompt, style: text.titleLarge),
                  if (q.visual != null) ...[
                    const SizedBox(height: 16),
                    SizedBox(height: 180, child: q.visual!(context)),
                  ],
                  const SizedBox(height: 16),
                  for (var i = 0; i < q.options.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Shake(
                        trigger: _shakes[i] ?? 0,
                        child: FilledButton.tonal(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            backgroundColor: _solved && i == q.answer
                                ? Colors.green.shade300
                                : null,
                          ),
                          onPressed: _wrong.contains(i) ? null : () => _pick(i),
                          child: Text(q.options[i]),
                        ),
                      ),
                    ),
                  if (_solved)
                    Card(
                      color: scheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(q.explanation, style: text.bodyLarge),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_solved)
            FilledButton(onPressed: _next, child: const Text('Continue')),
        ],
      ),
    );
  }
}
