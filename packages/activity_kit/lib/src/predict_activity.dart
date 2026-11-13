import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

import 'activity_header.dart';
import 'answer_panel.dart';
import 'content/choice.dart';
import 'experiment/experiment.dart';
import 'feedback_layout.dart';
import 'option_tile.dart';

/// How sure the learner is of a prediction. Asked before the reveal: errors
/// made with confidence are the ones feedback corrects best.
enum Confidence {
  guessing('Just guessing', Icons.help_outline_rounded),
  prettySure('Pretty sure', Icons.thumb_up_alt_rounded),
  certain('Totally sure', Icons.verified_rounded);

  const Confidence(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Predict, then find out: the learner commits to an answer and says how
/// sure they are, runs the [experiment], and sees what really happens.
/// Predictions are never marked as mistakes; making one earns [xp].
class PredictActivity implements ActivityPlugin, Validated {
  const PredictActivity({
    required this.question,
    required this.choices,
    required this.tryIt,
    required this.experiment,
    required this.outcome,
    this.xp = 5,
  });

  final String question;

  /// What really happens is [Right]; each [Wrong] carries a word to the
  /// learner who predicted it.
  final List<Choice> choices;

  /// What to do in the experiment, e.g. "Pump air into the balloon".
  final String tryIt;
  final Experiment experiment;

  /// What happened and why, shown after the experiment.
  final String outcome;
  final int xp;

  @override
  void validate() => checkOneRight(choices, question);

  @override
  Widget build(BuildContext context, ActivityHost host) =>
      _PredictView(activity: this, host: host);
}

/// Headline for the result, by whether the prediction held and how sure the
/// learner was.
String predictionTitle({required bool right, required Confidence confidence}) =>
    switch ((right, confidence)) {
      (true, Confidence.guessing) => 'Good guess!',
      (true, _) => 'You called it!',
      (false, Confidence.certain) => 'Whoa, a surprise!',
      (false, Confidence.prettySure) => 'Surprise!',
      (false, Confidence.guessing) => 'Now you know!',
    };

class _PredictView extends StatefulWidget {
  const _PredictView({required this.activity, required this.host});

  final PredictActivity activity;
  final ActivityHost host;

  @override
  State<_PredictView> createState() => _PredictViewState();
}

class _PredictViewState extends State<_PredictView> {
  int? _prediction;
  Confidence? _confidence;
  bool _observed = false;

  PredictActivity get _a => widget.activity;
  bool get _testing => _confidence != null && !_observed;
  bool get _right => _a.choices[_prediction!] is Right;

  void _predict(int option) {
    if (_confidence != null) return;
    HapticFeedback.selectionClick();
    setState(() => _prediction = option);
  }

  void _commit(Confidence confidence) {
    if (_confidence != null) return;
    HapticFeedback.selectionClick();
    setState(() => _confidence = confidence);
  }

  void _onObserved() {
    if (_observed || !_testing) return;
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _observed = true);
    });
  }

  String get _resultText => switch (_a.choices[_prediction!]) {
    Wrong(:final feedback) => '$feedback ${_a.outcome}',
    Right() => _a.outcome,
  };

  OptionState _stateOf(int i) =>
      i == _prediction ? OptionState.picked : OptionState.open;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
    child: FeedbackLayout(
      feedback: _observed
          ? _result()
          : _confidence == null
          ? null
          : _TryIt(
              key: const ValueKey('try'),
              instruction: _a.tryIt,
              prediction: _a.choices[_prediction!].text,
            ),
      page: (context, _) => _page(context),
    ),
  );

  Widget _result() => AnswerPanel(
    title: predictionTitle(right: _right, confidence: _confidence!),
    explanation: _resultText,
    lead: _right
        ? null
        : _AnswerLine(answer: _a.choices[rightIndex(_a.choices)].text),
    color: _right ? AnswerPanel.correctGreen : ActivityKind.predict.color,
    icon: _right ? Icons.check_circle_rounded : Icons.auto_awesome_rounded,
    onContinue: () => widget.host.complete(ActivityResult(xp: _a.xp)),
  );

  /// The choices stay in place throughout, so the experiment never changes
  /// size; instructions and the result slide up over them.
  Widget _page(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ActivityHeader(kind: ActivityKind.predict),
        const SizedBox(height: 12),
        Text(_a.question, style: text.titleLarge?.copyWith(height: 1.3)),
        const SizedBox(height: 12),
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _testing
                    ? ActivityKind.predict.color
                    : scheme.outlineVariant,
                width: _testing ? 3 : 2,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            padding: const EdgeInsets.all(12),
            child: _a.experiment.build(
              context,
              active: _testing,
              onObserved: _onObserved,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _choices(text),
      ],
    );
  }

  /// Hidden but still taking up its space.
  Widget _kept({required bool visible, required Widget child}) => Visibility(
    visible: visible,
    maintainSize: true,
    maintainAnimation: true,
    maintainState: true,
    child: child,
  );

  Widget _choices(TextTheme text) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < _a.choices.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: OptionTile(
            letter: String.fromCharCode(65 + i),
            label: _a.choices[i].text,
            state: _stateOf(i),
            onTap: () => _predict(i),
          ),
        ),
      _kept(
        visible: _prediction != null && _confidence == null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4),
            Text('How sure are you?', style: text.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final (i, c) in Confidence.values.indexed) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _ConfidenceButton(confidence: c, onTap: _commit),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    ],
  );
}

class _ConfidenceButton extends StatelessWidget {
  const _ConfidenceButton({required this.confidence, required this.onTap});

  final Confidence confidence;
  final ValueChanged<Confidence> onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const color = Color(0xFF7B1FA2);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      builder: (context, t, child) =>
          Transform.scale(scale: 0.85 + 0.15 * t, child: child),
      child: Material(
        color: Color.alphaBlend(
          color.withValues(alpha: 0.08),
          scheme.surfaceContainerLowest,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withValues(alpha: 0.35), width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onTap(confidence),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Column(
              children: [
                Icon(confidence.icon, color: color),
                const SizedBox(height: 4),
                Text(
                  confidence.label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// While the experiment runs: what to do, and the prediction being tested.
class _TryIt extends StatelessWidget {
  const _TryIt({
    required this.instruction,
    required this.prediction,
    super.key,
  });

  final String instruction;
  final String prediction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    const color = Color(0xFF7B1FA2);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          color.withValues(alpha: 0.1),
          scheme.surfaceContainerLowest,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: overlayShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.touch_app_rounded, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  instruction,
                  style: text.titleMedium?.copyWith(color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'You predicted: $prediction',
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// The real answer, shown when the prediction missed.
class _AnswerLine extends StatelessWidget {
  const _AnswerLine({required this.answer});

  final String answer;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Icon(
        Icons.check_rounded,
        size: 20,
        color: AnswerPanel.correctGreen,
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          answer,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(color: AnswerPanel.correctGreen),
        ),
      ),
    ],
  );
}
