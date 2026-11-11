import 'dart:async';
import 'dart:math';

import 'package:activity_kit/activity_kit.dart';
import 'package:flutter/material.dart';

import 'fact_pill.dart';
import 'pop.dart';

const _canvas = Size(320, 300);
const _pivot = Offset(160, 84);
const _armLength = 116.0;
const _panDrop = 118.0;
const _panHalfWidth = 44.0;
const _maxTilt = 0.16;
const _balloonColor = Color(0xFFE53935);
const _pumpsToFill = 4;

/// Two identical empty balloons balance. Each pump of air fills the right
/// one: it grows, because air takes up space, and the scale tips toward it,
/// because air has mass.
const Experiment balloonExperiment = _balloonExperiment;

Widget _balloonExperiment(
  BuildContext context,
  bool active,
  VoidCallback onObserved,
) => _BalloonExperiment(active: active, onObserved: onObserved);

class _BalloonExperiment extends StatefulWidget {
  const _BalloonExperiment({required this.active, required this.onObserved});

  final bool active;
  final VoidCallback onObserved;

  @override
  State<_BalloonExperiment> createState() => _BalloonExperimentState();
}

class _BalloonExperimentState extends State<_BalloonExperiment> {
  int _pumps = 0;
  Timer? _settle;

  bool get _full => _pumps == _pumpsToFill;

  @override
  void dispose() {
    _settle?.cancel();
    super.dispose();
  }

  void _pump() {
    setState(() => _pumps++);
    if (_full) {
      _settle = Timer(const Duration(milliseconds: 1400), widget.onObserved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final air = _pumps / _pumpsToFill;
    return Column(
      children: [
        Expanded(
          child: FittedBox(
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: air),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
              builder: (context, air, _) => TweenAnimationBuilder<double>(
                tween: Tween(end: air * _maxTilt),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.elasticOut,
                builder: (context, tilt, _) => CustomPaint(
                  size: _canvas,
                  painter: _BalancePainter(
                    air: air.clamp(0.0, 1.1),
                    tilt: tilt,
                    colors: scheme,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_full)
          const Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              Pop(
                visible: true,
                child: FactPill(
                  'Takes up space',
                  icon: Icons.view_in_ar_rounded,
                ),
              ),
              Pop(
                visible: true,
                delay: Duration(milliseconds: 300),
                child: FactPill('Has mass', icon: Icons.scale_rounded),
              ),
            ],
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _pumpsToFill; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 6),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _pumps ? _balloonColor : scheme.outlineVariant,
                  ),
                ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: widget.active ? _pump : null,
                style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                icon: const Icon(Icons.air_rounded),
                label: const Text('Pump'),
              ),
            ],
          ),
      ],
    );
  }
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
