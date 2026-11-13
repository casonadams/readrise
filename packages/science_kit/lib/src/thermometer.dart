import 'package:flutter/material.dart';

import 'science_colors.dart';

/// The temperatures a [Thermometer] shows, in degrees Celsius.
const coldestCelsius = -20.0;
const hottestCelsius = 120.0;

/// Cold blue through heat red across the thermometer's range.
Color temperatureColor(double celsius) => Color.lerp(
  ScienceColors.cold,
  ScienceColors.heat,
  ((celsius - coldestCelsius) / (hottestCelsius - coldestCelsius)).clamp(
    0.0,
    1.0,
  ),
)!;

/// A thermometer filled to [celsius], marked at 0 and 100 degrees.
class Thermometer extends StatelessWidget {
  const Thermometer(this.celsius, {super.key});

  final double celsius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _ThermometerPainter(
        celsius: celsius,
        track: scheme.outlineVariant,
        ink: scheme.onSurfaceVariant,
      ),
    );
  }
}

class _ThermometerPainter extends CustomPainter {
  const _ThermometerPainter({
    required this.celsius,
    required this.track,
    required this.ink,
  });

  final double celsius;
  final Color track;
  final Color ink;

  static const _tubeWidth = 14.0;
  static const _bulbRadius = 15.0;
  static const _tubeX = 20.0;

  @override
  void paint(Canvas canvas, Size size) {
    final top = 6.0;
    final bulb = Offset(_tubeX, size.height - _bulbRadius - 2);
    final bottom = bulb.dy - _bulbRadius * 0.6;
    double yAt(double c) =>
        bottom -
        (bottom - top - 8) *
            ((c - coldestCelsius) / (hottestCelsius - coldestCelsius));

    final tube = RRect.fromLTRBR(
      _tubeX - _tubeWidth / 2,
      top,
      _tubeX + _tubeWidth / 2,
      bulb.dy,
      const Radius.circular(_tubeWidth / 2),
    );
    canvas.drawRRect(tube, Paint()..color = track);
    canvas.drawCircle(bulb, _bulbRadius, Paint()..color = track);

    final fill = Paint()..color = temperatureColor(celsius);
    final level = yAt(celsius.clamp(coldestCelsius, hottestCelsius));
    canvas.drawRRect(
      RRect.fromLTRBR(
        _tubeX - _tubeWidth / 2 + 3,
        level,
        _tubeX + _tubeWidth / 2 - 3,
        bulb.dy,
        const Radius.circular(4),
      ),
      fill,
    );
    canvas.drawCircle(bulb, _bulbRadius - 3, fill);

    for (final (mark, label) in [(0.0, '0\u00B0'), (100.0, '100\u00B0')]) {
      final y = yAt(mark);
      canvas.drawLine(
        Offset(_tubeX + _tubeWidth / 2 + 2, y),
        Offset(_tubeX + _tubeWidth / 2 + 8, y),
        Paint()
          ..color = ink
          ..strokeWidth = 2,
      );
      final painter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: ink,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        Offset(_tubeX + _tubeWidth / 2 + 10, y - painter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(_ThermometerPainter old) =>
      old.celsius != celsius || old.track != track || old.ink != ink;
}
