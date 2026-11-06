import 'dart:math';

import 'package:flutter/material.dart';

/// A short burst of falling confetti. Draws nothing when the user has asked
/// the system to reduce motion.
class Confetti extends StatefulWidget {
  const Confetti({this.pieces = 70, super.key});

  final int pieces;

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<Confetti>
    with SingleTickerProviderStateMixin {
  static const _colors = [
    Colors.red,
    Colors.orange,
    Colors.amber,
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.pink,
  ];

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..forward();
  late final List<_Piece> _pieces = _makePieces(Random(3), widget.pieces);

  static List<_Piece> _makePieces(Random random, int count) => [
    for (var i = 0; i < count; i++)
      _Piece(
        x: random.nextDouble(),
        drift: (random.nextDouble() - 0.5) * 0.3,
        delay: random.nextDouble() * 0.35,
        speed: 0.6 + random.nextDouble() * 0.5,
        spin: random.nextDouble() * 6,
        size: 6 + random.nextDouble() * 8,
        color: _colors[random.nextInt(_colors.length)],
      ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: ExcludeSemantics(
        child: CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_pieces, _controller),
        ),
      ),
    );
  }
}

class _Piece {
  const _Piece({
    required this.x,
    required this.drift,
    required this.delay,
    required this.speed,
    required this.spin,
    required this.size,
    required this.color,
  });

  final double x;
  final double drift;
  final double delay;
  final double speed;
  final double spin;
  final double size;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.animation) : super(repaint: animation);

  final List<_Piece> pieces;
  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      final t = ((animation.value - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (t == 0 || t == 1) continue;
      final dx = (p.x + p.drift * t) * size.width;
      final dy = (-0.1 + 1.2 * t * p.speed) * size.height;
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(p.spin * t * 2 * pi);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size,
          height: p.size * 0.5,
        ),
        Paint()..color = p.color.withValues(alpha: 1 - t * 0.4),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => false;
}
