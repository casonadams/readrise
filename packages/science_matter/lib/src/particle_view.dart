import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'matter_state.dart';
import 'particle_sim.dart';

/// Animated particles for [state]; [energy] (0..1) sets how fast they move.
/// [count] keeps fewer particles than the full set (liquid or gas only).
class ParticleView extends StatefulWidget {
  const ParticleView({
    required this.state,
    this.energy = 0.5,
    this.count,
    super.key,
  });

  final MatterState state;
  final double energy;
  final int? count;

  @override
  State<ParticleView> createState() => _ParticleViewState();
}

class _ParticleViewState extends State<ParticleView>
    with SingleTickerProviderStateMixin {
  final ParticleSim _sim = ParticleSim();
  final ValueNotifier<int> _frame = ValueNotifier(0);
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.count case final count?) _sim.resize(count);
    _ticker = createTicker((elapsed) {
      final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
      _last = elapsed;
      _sim.step(dt, widget.state, widget.energy);
      _frame.value++;
    })..start();
  }

  @override
  void didUpdateWidget(ParticleView old) {
    super.didUpdateWidget(old);
    if (widget.count case final count? when count != old.count) {
      _sim.resize(count);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Particles in a ${widget.state.name}',
      child: TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: particleColor(widget.state)),
        duration: const Duration(milliseconds: 500),
        builder: (context, color, _) => DecoratedBox(
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              color!.withValues(alpha: 0.06),
              scheme.surfaceContainerLowest,
            ),
            border: Border.all(color: scheme.outlineVariant, width: 2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: LayoutBuilder(
              builder: (context, box) {
                _sim.fit(box.maxHeight / box.maxWidth);
                return CustomPaint(
                  size: Size.infinite,
                  painter: _ParticlePainter(
                    sim: _sim,
                    color: color,
                    repaint: _frame,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// The colour particles are drawn in for [state].
Color particleColor(MatterState state) => switch (state) {
  MatterState.solid => Colors.indigo,
  MatterState.liquid => Colors.blue,
  MatterState.gas => Colors.lightBlue,
};

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.sim,
    required this.color,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final ParticleSim sim;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final body = Paint()..color = color;
    final shine = Paint()..color = Colors.white.withValues(alpha: 0.45);
    final scale = min(size.width / sim.width, size.height / sim.height);
    final origin = Offset(
      (size.width - sim.width * scale) / 2,
      size.height - sim.height * scale,
    );
    final r = ParticleSim.radius * scale;
    for (final p in sim.particles) {
      final at = origin + Offset(p.x, p.y) * scale;
      canvas.drawCircle(at, r, body);
      canvas.drawCircle(at + Offset(-r * 0.35, -r * 0.35), r * 0.32, shine);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.color != color;
}
