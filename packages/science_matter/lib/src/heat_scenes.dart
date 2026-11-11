import 'package:activity_kit/activity_kit.dart';
import 'package:flutter/material.dart';

import 'fact_pill.dart';
import 'matter_state.dart';
import 'particle_view.dart';
import 'pop.dart';

const _coldest = -20.0;
const _hottest = 120.0;
const _cold = Color(0xFF1E88E5);
const _hot = Color(0xFFE53935);

/// Water moving from [from] to [to] degrees Celsius while its step is shown.
class HeatStage {
  const HeatStage(this.from, this.to);

  final double from;
  final double to;
}

/// How fast particles move at [celsius], from [energyAt].
String speedWord(double celsius) {
  final energy = energyAt(celsius);
  return energy < 0.35
      ? 'Slow'
      : energy < 0.7
      ? 'Medium'
      : 'Fast';
}

/// The name of the change from [from] to [to], or null when they match.
/// Only neighbouring states are named.
String? changeName(MatterState from, MatterState to) => switch ((from, to)) {
  (MatterState.solid, MatterState.liquid) => 'Melting',
  (MatterState.liquid, MatterState.solid) => 'Freezing',
  (MatterState.liquid, MatterState.gas) => 'Boiling',
  (MatterState.gas, MatterState.liquid) => 'Condensing',
  _ => null,
};

/// Water heating or cooling through the stage for each step, with a
/// thermometer, the particles, and where it sits on solid-liquid-gas.
ExplainerScene heatScene(List<HeatStage> stages) => (context, step) {
  final stage = stages[step];
  final from = waterStateAt(stage.from);
  final to = waterStateAt(stage.to);
  final text = Theme.of(context).textTheme;
  return TweenAnimationBuilder<double>(
    key: ValueKey(step),
    tween: Tween(begin: stage.from, end: stage.to),
    duration: const Duration(milliseconds: 2500),
    curve: Curves.easeInOut,
    builder: (context, celsius, _) => Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: AspectRatio(
            aspectRatio: 1.2,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 56,
                  child: CustomPaint(
                    painter: _ThermometerPainter(
                      celsius: celsius,
                      track: Theme.of(context).colorScheme.outlineVariant,
                      ink: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ParticleView(
                    state: waterStateAt(celsius),
                    energy: energyAt(celsius),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${celsius.round()}\u00B0C',
              style: text.headlineSmall?.copyWith(
                color: _temperatureColor(celsius),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 12),
            FactPill(
              'Particles: ${speedWord(celsius)}',
              icon: Icons.speed_rounded,
              color: _temperatureColor(celsius),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _StateTrack(
          current: waterStateAt(celsius),
          change: changeName(from, to),
          between: from.index < to.index ? from : to,
          heating: stage.to > stage.from,
        ),
      ],
    ),
  );
};

Color _temperatureColor(double celsius) => Color.lerp(
  _cold,
  _hot,
  ((celsius - _coldest) / (_hottest - _coldest)).clamp(0.0, 1.0),
)!;

/// Solid, liquid and gas in a row. The current state is filled in, and the
/// link for a change underway names it and whether energy goes in or out.
class _StateTrack extends StatelessWidget {
  const _StateTrack({
    required this.current,
    required this.change,
    required this.between,
    required this.heating,
  });

  final MatterState current;
  final String? change;

  /// The lower of the two states the change links.
  final MatterState between;
  final bool heating;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (final state in MatterState.values) {
      if (state != MatterState.solid) {
        final link = MatterState.values[state.index - 1];
        children.add(
          Expanded(
            child: _Link(
              label: link == between ? change : null,
              heating: heating,
            ),
          ),
        );
      }
      children.add(_Node(state: state, on: state == current));
    }
    return Row(children: children);
  }
}

class _Node extends StatelessWidget {
  const _Node({required this.state, required this.on});

  final MatterState state;
  final bool on;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = particleColor(state);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: on ? color : scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: on ? color : scheme.outlineVariant, width: 2),
      ),
      child: Text(
        '${state.name[0].toUpperCase()}${state.name.substring(1)}',
        style: Theme.of(context).textTheme.labelLarge
            ?.copyWith(color: on ? Colors.white : scheme.onSurfaceVariant),
      ),
    );
  }
}

class _Link extends StatelessWidget {
  const _Link({required this.label, required this.heating});

  final String? label;
  final bool heating;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = label != null;
    final color = active ? (heating ? _hot : _cold) : scheme.outlineVariant;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 18,
          child: Pop(
            visible: active,
            child: Text(
              label ?? '',
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: color),
            ),
          ),
        ),
        Row(
          children: [
            if (active && !heating)
              Icon(Icons.arrow_back_rounded, size: 16, color: color),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 3,
                color: color,
              ),
            ),
            if (active && heating)
              Icon(Icons.arrow_forward_rounded, size: 16, color: color),
          ],
        ),
        SizedBox(
          height: 18,
          child: Pop(
            visible: active,
            child: Text(
              !active
                  ? ''
                  : heating
                  ? '+ energy'
                  : '\u2212 energy',
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: color),
            ),
          ),
        ),
      ],
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
        bottom - (bottom - top - 8) * ((c - _coldest) / (_hottest - _coldest));

    final tube = RRect.fromLTRBR(
      _tubeX - _tubeWidth / 2,
      top,
      _tubeX + _tubeWidth / 2,
      bulb.dy,
      const Radius.circular(_tubeWidth / 2),
    );
    canvas.drawRRect(tube, Paint()..color = track);
    canvas.drawCircle(bulb, _bulbRadius, Paint()..color = track);

    final fill = Paint()..color = _temperatureColor(celsius);
    final level = yAt(celsius.clamp(_coldest, _hottest));
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
