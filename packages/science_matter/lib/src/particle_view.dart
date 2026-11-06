import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'matter_state.dart';
import 'particle_sim.dart';

/// Animated particles for [state]; [energy] (0..1) sets how fast they move.
class ParticleView extends StatefulWidget {
  const ParticleView({required this.state, this.energy = 0.5, super.key});

  final MatterState state;
  final double energy;

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
    _ticker = createTicker((elapsed) {
      final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
      _last = elapsed;
      _sim.step(dt, widget.state, widget.energy);
      _frame.value++;
    })..start();
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
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          border: Border.all(color: scheme.outline, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CustomPaint(
            size: Size.infinite,
            painter: _ParticlePainter(
              sim: _sim,
              color: switch (widget.state) {
                MatterState.solid => Colors.indigo,
                MatterState.liquid => Colors.blue,
                MatterState.gas => Colors.lightBlue,
              },
              repaint: _frame,
            ),
          ),
        ),
      ),
    );
  }
}

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
    final paint = Paint()..color = color;
    final r = ParticleSim.radius * size.shortestSide;
    for (final p in sim.particles) {
      canvas.drawCircle(Offset(p.x * size.width, p.y * size.height), r, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.color != color;
}
