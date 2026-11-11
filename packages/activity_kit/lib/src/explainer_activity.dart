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
  late final Speaker _speaker;
  int _step = 0;
  bool _sound = true;

  ExplainerActivity get _a => widget.activity;
  bool get _last => _step == _a.steps.length - 1;

  @override
  void initState() {
    super.initState();
    _speaker = widget.host.speaker;
    // The card this one replaces is disposed after this build; its dispose
    // stops speech, so narration must start after that.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _speak();
    });
  }

  @override
  void dispose() {
    // Interrupt narration when the learner leaves the card.
    _speaker.speak('');
    super.dispose();
  }

  void _speak() {
    if (_sound) _speaker.speak(_a.steps[_step].caption);
  }

  void _go(int step) {
    HapticFeedback.selectionClick();
    setState(() => _step = step);
    _speak();
  }

  void _toggleSound() {
    setState(() => _sound = !_sound);
    _sound ? _speak() : _speaker.speak('');
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
          _CaptionCard(
            caption: _a.steps[_step].caption,
            sound: _sound,
            onToggleSound: _toggleSound,
          ),
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

/// The spoken line, sliding in fresh on every step.
class _CaptionCard extends StatelessWidget {
  const _CaptionCard({
    required this.caption,
    required this.sound,
    required this.onToggleSound,
  });

  final String caption;
  final bool sound;
  final VoidCallback onToggleSound;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.fromLTRB(20, 14, 8, 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
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
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: sound ? 'Turn sound off' : 'Turn sound on',
            onPressed: onToggleSound,
            isSelected: sound,
            icon: const Icon(Icons.volume_off_rounded),
            selectedIcon: const Icon(Icons.volume_up_rounded),
          ),
        ],
      ),
    );
  }
}
