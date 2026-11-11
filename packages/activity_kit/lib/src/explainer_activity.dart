import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

import 'step_dots.dart';

/// One beat of an explainer: a caption that is shown and spoken while the
/// scene displays that step.
class ExplainerStep {
  const ExplainerStep(this.caption);

  final String caption;
}

/// Builds the picture for the step the learner is on. Rebuilt on every step
/// change, so use implicit animations to move between steps.
typedef ExplainerScene = Widget Function(BuildContext context, int step);

/// A short animated explanation told one captioned step at a time.
/// Next moves forward, back returns, and the last step becomes Continue.
class ExplainerActivity implements ActivityPlugin {
  const ExplainerActivity({
    required this.title,
    required this.steps,
    required this.scene,
  });

  final String title;
  final List<ExplainerStep> steps;
  final ExplainerScene scene;

  @override
  Widget build(BuildContext context, ActivityHost host) =>
      _ExplainerView(activity: this, host: host);
}

class _ExplainerView extends StatefulWidget {
  const _ExplainerView({required this.activity, required this.host});

  final ExplainerActivity activity;
  final ActivityHost host;

  @override
  State<_ExplainerView> createState() => _ExplainerViewState();
}

class _ExplainerViewState extends State<_ExplainerView> {
  int _step = 0;

  ExplainerActivity get _a => widget.activity;
  bool get _last => _step == _a.steps.length - 1;

  void _go(int step) {
    HapticFeedback.selectionClick();
    setState(() => _step = step);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        children: [
          Text(
            _a.title,
            style: text.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          StepDots(count: _a.steps.length, current: _step),
          const SizedBox(height: 8),
          Expanded(child: _a.scene(context, _step)),
          const SizedBox(height: 12),
          _CaptionCard(caption: _a.steps[_step].caption),
          const SizedBox(height: 16),
          Row(
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: _step == 0
                    ? const SizedBox(height: 56)
                    : Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: SizedBox.square(
                          dimension: 56,
                          child: IconButton.outlined(
                            tooltip: 'Previous step',
                            onPressed: () => _go(_step - 1),
                            style: IconButton.styleFrom(
                              side: BorderSide(
                                color: scheme.outlineVariant,
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                        ),
                      ),
              ),
              Expanded(
                child: FilledButton(
                  onPressed: _last
                      ? () => widget.host.complete(const ActivityResult())
                      : () => _go(_step + 1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_last ? 'Continue' : 'Next'),
                      if (!_last) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The step's line, sliding in fresh on every step.
class _CaptionCard extends StatelessWidget {
  const _CaptionCard({required this.caption});

  final String caption;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant, width: 2),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.centerLeft,
          children: [...previous, ?current],
        ),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.25),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: Text(
          caption,
          key: ValueKey(caption),
          style: text.titleMedium?.copyWith(height: 1.35),
        ),
      ),
    );
  }
}
