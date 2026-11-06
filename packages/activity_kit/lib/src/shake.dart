import 'dart:math';

import 'package:flutter/widgets.dart';

/// Wiggles [child] sideways each time [trigger] increases. Does nothing when
/// the user has asked the system to reduce motion.
class Shake extends StatelessWidget {
  const Shake({required this.trigger, required this.child, super.key});

  final int trigger;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (trigger == 0 || MediaQuery.of(context).disableAnimations) return child;
    return TweenAnimationBuilder<double>(
      key: ValueKey(trigger),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      builder: (context, t, child) => Transform.translate(
        offset: Offset(sin(t * pi * 5) * (1 - t) * 12, 0),
        child: child,
      ),
      child: child,
    );
  }
}
