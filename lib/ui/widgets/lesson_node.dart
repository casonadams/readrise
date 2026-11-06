import 'dart:math';

import 'package:flutter/material.dart';

enum NodeState { locked, current, done }

/// One stop on a learning path: a chunky round button with a 3D edge.
/// The current lesson bobs and pulses unless the user reduced motion.
class LessonNode extends StatefulWidget {
  const LessonNode({
    required this.title,
    required this.state,
    required this.onTap,
    this.stars = 0,
    super.key,
  });

  static const size = 96.0;

  final String title;
  final NodeState state;
  final int stars;
  final VoidCallback onTap;

  @override
  State<LessonNode> createState() => _LessonNodeState();
}

class _LessonNodeState extends State<LessonNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(LessonNode old) {
    super.didUpdateWidget(old);
    _syncAnimation();
  }

  void _syncAnimation() {
    final animate =
        widget.state == NodeState.current &&
        !MediaQuery.of(context).disableAnimations;
    if (animate) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (face, edge, ink) = switch (widget.state) {
      NodeState.done => (
        Colors.amber.shade400,
        Colors.amber.shade800,
        Colors.brown.shade900,
      ),
      NodeState.current => (
        scheme.primary,
        HSLColor.fromColor(scheme.primary).withLightness(0.25).toColor(),
        scheme.onPrimary,
      ),
      NodeState.locked => (
        scheme.surfaceContainerHighest,
        scheme.outlineVariant,
        scheme.outline,
      ),
    };
    final description = switch (widget.state) {
      NodeState.done => '${widget.stars} of 3 stars',
      NodeState.current => 'start here',
      NodeState.locked => 'locked',
    };
    return Semantics(
      container: true,
      button: true,
      label: '${widget.title}, $description',
      excludeSemantics: true,
      onTap: widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: widget.state == NodeState.current
                ? _StartBubble(animation: _pulse)
                : null,
          ),
          GestureDetector(
            onTap: widget.onTap,
            child: SizedBox(
              width: LessonNode.size + 16,
              height: LessonNode.size + 22,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  if (widget.state == NodeState.current)
                    AnimatedBuilder(
                      animation: _pulse,
                      builder: (context, _) => Positioned(
                        top: 8 - 10 * _pulse.value,
                        child: Container(
                          width: LessonNode.size + 20 * _pulse.value,
                          height: LessonNode.size + 20 * _pulse.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: scheme.primary.withValues(
                                alpha: 0.5 * (1 - _pulse.value),
                              ),
                              width: 4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned(top: 14, child: _disc(edge, null)),
                  Positioned(
                    top: 8,
                    child: _disc(
                      face,
                      Center(
                        child: widget.state == NodeState.locked
                            ? Icon(Icons.lock_rounded, size: 36, color: ink)
                            : Padding(
                                padding: const EdgeInsets.all(10),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    widget.title,
                                    maxLines: 1,
                                    softWrap: false,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: ink,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 28,
            child: widget.state == NodeState.done
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var s = 1; s <= 3; s++)
                        Icon(
                          s <= widget.stars
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 24,
                          color: s <= widget.stars
                              ? Colors.amber.shade600
                              : scheme.outline,
                        ),
                    ],
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _disc(Color color, Widget? child) => Container(
    width: LessonNode.size,
    height: LessonNode.size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    child: child,
  );
}

class _StartBubble extends StatelessWidget {
  const _StartBubble({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -4 * sin(animation.value * pi)),
        child: child,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'START',
              style: TextStyle(
                color: scheme.onPrimary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
          Icon(Icons.arrow_drop_down_rounded, size: 20, color: scheme.primary),
        ],
      ),
    );
  }
}
