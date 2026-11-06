import 'package:flutter/material.dart';

import '../engine/progress.dart';
import '../engine/subjects.dart';
import 'widgets/confetti.dart';
import 'widgets/page_frame.dart';
import 'widgets/stat_chip.dart';

/// Celebration at the end of a lesson: stars pop in, XP counts up, and the
/// way forward is one tap away.
class LessonResult extends StatefulWidget {
  const LessonResult({
    required this.outcome,
    required this.streak,
    required this.next,
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final LessonOutcome outcome;
  final int streak;

  /// The lesson to offer next, if any.
  final LessonRef? next;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  State<LessonResult> createState() => _LessonResultState();
}

class _LessonResultState extends State<LessonResult>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _controller.value = 1;
    } else if (!_controller.isAnimating && _controller.value == 0) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static String _headline(int stars) => switch (stars) {
    3 => 'Perfect!',
    2 => 'Great job!',
    _ => 'Nice work!',
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final stars = widget.outcome.stars;
    final next = widget.next;
    return Scaffold(
      body: Stack(
        children: [
          if (stars >= 2) const Positioned.fill(child: Confetti()),
          SafeArea(
            child: PageFrame(
              child: LayoutBuilder(
                builder: (context, box) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: box.maxHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const Spacer(),
                            Text(
                              _headline(stars),
                              style: text.displaySmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Semantics(
                              container: true,
                              label: '$stars of 3 stars',
                              excludeSemantics: true,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (var i = 0; i < 3; i++)
                                    _PoppingStar(
                                      earned: i < stars,
                                      animation: _controller,
                                      start: i * 0.15,
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            AnimatedBuilder(
                              animation: _controller,
                              builder: (context, _) {
                                final shown =
                                    (widget.outcome.xp *
                                            Curves.easeOut.transform(
                                              ((_controller.value - 0.3) / 0.7)
                                                  .clamp(0.0, 1.0),
                                            ))
                                        .round();
                                return Semantics(
                                  container: true,
                                  label: '${widget.outcome.xp} XP earned',
                                  excludeSemantics: true,
                                  child: Text(
                                    '+$shown XP',
                                    style: text.headlineLarge?.copyWith(
                                      color: scheme.primary,
                                    ),
                                  ),
                                );
                              },
                            ),
                            if (widget.streak > 0) ...[
                              const SizedBox(height: 16),
                              StatChip(
                                emoji: '\u{1F525}',
                                value: widget.streak,
                                label: 'day streak',
                                highlight: true,
                              ),
                            ],
                            const Spacer(),
                            if (next != null)
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: widget.onNext,
                                  child: Text('Next: ${next.lesson.title}'),
                                ),
                              ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: next == null
                                  ? FilledButton(
                                      onPressed: widget.onBack,
                                      child: const Text('Back to the path'),
                                    )
                                  : TextButton(
                                      onPressed: widget.onBack,
                                      child: const Text('Back to the path'),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PoppingStar extends StatelessWidget {
  const _PoppingStar({
    required this.earned,
    required this.animation,
    required this.start,
  });

  final bool earned;
  final Animation<double> animation;
  final double start;

  @override
  Widget build(BuildContext context) {
    final scale = CurvedAnimation(
      parent: animation,
      curve: Interval(
        start,
        (start + 0.4).clamp(0.0, 1.0),
        curve: Curves.elasticOut,
      ),
    );
    return ScaleTransition(
      scale: scale,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Icon(
          earned ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 76,
          color: earned
              ? Colors.amber.shade500
              : Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}
