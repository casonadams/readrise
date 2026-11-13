import 'dart:math';

import 'package:flutter/material.dart';

const _canvas = Size(320, 300);
const _pivot = Offset(160, 84);
const _armLength = 116.0;
const _panDrop = 118.0;
const _panHalfWidth = 44.0;
const _balloonColor = Color(0xFFE53935);

/// A balance with an empty balloon on the left and one holding [air] (0 to
/// about 1) on the right, the arm tipped by [tilt] radians.
class BalloonBalance extends StatelessWidget {
  const BalloonBalance({required this.air, required this.tilt, super.key});

  final double air;
  final double tilt;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: _canvas,
    painter: _BalancePainter(
      air: air,
      tilt: tilt,
      colors: Theme.of(context).colorScheme,
    ),
  );
}

class _BalancePainter extends CustomPainter {
  const _BalancePainter({
    required this.air,
    required this.tilt,
    required this.colors,
  });

  final double air;
  final double tilt;
  final ColorScheme colors;

  @override
  void paint(Canvas canvas, Size size) {
    final metal = colors.onSurfaceVariant;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(_pivot.dx, 288), width: 120, height: 14),
        const Radius.circular(7),
      ),
      Paint()..color = metal,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(_pivot.dx - 5, _pivot.dy, _pivot.dx + 5, 284),
        const Radius.circular(5),
      ),
      Paint()..color = metal,
    );

    final arm = Offset(cos(tilt), sin(tilt)) * _armLength;
    canvas.drawLine(
      _pivot - arm,
      _pivot + arm,
      Paint()
        ..color = metal
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(_pivot, 11, Paint()..color = colors.primary);
    canvas.drawCircle(_pivot, 4, Paint()..color = colors.onPrimary);

    _balloon(canvas, _pan(canvas, _pivot - arm), 0);
    _balloon(canvas, _pan(canvas, _pivot + arm), air);
  }

  /// Draws a hanging pan and returns the middle of the surface it holds.
  Offset _pan(Canvas canvas, Offset end) {
    final string = Paint()
      ..color = colors.outline
      ..strokeWidth = 2;
    final rim = end + const Offset(0, _panDrop);
    canvas.drawLine(end, rim - const Offset(_panHalfWidth, 0), string);
    canvas.drawLine(end, rim + const Offset(_panHalfWidth, 0), string);
    canvas.drawCircle(end, 4, Paint()..color = colors.onSurfaceVariant);
    final dish = Path()
      ..moveTo(rim.dx - _panHalfWidth, rim.dy)
      ..quadraticBezierTo(rim.dx, rim.dy + 22, rim.dx + _panHalfWidth, rim.dy)
      ..close();
    canvas.drawPath(dish, Paint()..color = colors.onSurfaceVariant);
    return rim + const Offset(0, 4);
  }

  void _balloon(Canvas canvas, Offset base, double air) {
    final width = 26 + 70 * air;
    final height = 30 + 70 * air;
    final body = Rect.fromCenter(
      center: base - Offset(0, height / 2 + 6),
      width: width,
      height: height,
    );
    canvas.drawOval(
      body,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.5),
          radius: 0.9,
          colors: [
            Color.lerp(_balloonColor, Colors.white, 0.35)!,
            _balloonColor,
            Color.lerp(_balloonColor, Colors.black, 0.25)!,
          ],
          stops: const [0, 0.55, 1],
        ).createShader(body),
    );

    canvas.drawOval(
      Rect.fromLTWH(
        body.left + width * 0.2,
        body.top + height * 0.14,
        width * 0.16,
        height * 0.2,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.5),
    );
    final knot = Offset(body.center.dx, body.bottom - 1);
    canvas.drawPath(
      Path()
        ..moveTo(knot.dx, knot.dy)
        ..lineTo(knot.dx - 5, knot.dy + 7)
        ..lineTo(knot.dx + 5, knot.dy + 7)
        ..close(),
      Paint()..color = Color.lerp(_balloonColor, Colors.black, 0.25)!,
    );
  }

  @override
  bool shouldRepaint(_BalancePainter old) =>
      old.air != air || old.tilt != tilt || old.colors != colors;
}
