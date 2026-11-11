import 'dart:math';

import 'package:flutter/material.dart';

/// A friendly classmate who appears in activities.
class Kid {
  const Kid(this.name, {required this.skin, required this.hair});

  final String name;
  final Color skin;
  final Color hair;
}

/// A round cartoon face for a [Kid].
class KidAvatar extends StatelessWidget {
  const KidAvatar({required this.kid, this.size = 56, super.key});

  final Kid kid;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _FacePainter(kid)),
  );
}

class _FacePainter extends CustomPainter {
  const _FacePainter(this.kid);

  final Kid kid;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final c = Offset(r, r);
    canvas.drawCircle(c, r, Paint()..color = kid.hair);
    canvas.drawCircle(
      c + Offset(0, r * 0.12),
      r * 0.82,
      Paint()..color = kid.skin,
    );
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r * 0.95),
      pi * 1.05,
      pi * 0.9,
      true,
      Paint()..color = kid.hair,
    );
    final ink = Paint()..color = const Color(0xFF3E2723);
    canvas.drawCircle(c + Offset(-r * 0.3, r * 0.12), r * 0.09, ink);
    canvas.drawCircle(c + Offset(r * 0.3, r * 0.12), r * 0.09, ink);
    canvas.drawArc(
      Rect.fromCenter(
        center: c + Offset(0, r * 0.35),
        width: r * 0.6,
        height: r * 0.4,
      ),
      0.15 * pi,
      0.7 * pi,
      false,
      ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.08
        ..strokeCap = StrokeCap.round,
    );
    final cheek = Paint()
      ..color = const Color(0xFFFF8A80).withValues(alpha: 0.5);
    canvas.drawCircle(c + Offset(-r * 0.52, r * 0.36), r * 0.11, cheek);
    canvas.drawCircle(c + Offset(r * 0.52, r * 0.36), r * 0.11, cheek);
  }

  @override
  bool shouldRepaint(_FacePainter old) => old.kid != kid;
}
