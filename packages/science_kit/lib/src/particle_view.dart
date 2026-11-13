import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'particles/matter_state.dart';
import 'particles/particle_sim.dart';
import 'science_colors.dart';

/// Animated particles for [state]; [energy] (0..1) sets how fast they move.
/// [count] keeps fewer particles than the full set (liquid or gas only).
/// [seed] sets the particles' starting directions. [dissolved] sugar
/// particles move with a liquid; [undissolved] ones sit in a crystal.
class ParticleView extends StatefulWidget {
  const ParticleView({
    required this.state,
    this.energy = 0.5,
    this.count,
    this.seed = 0,
    this.dissolved = 0,
    this.undissolved = 0,
    super.key,
  });

  final MatterState state;
  final double energy;
  final int? count;
  final int seed;
  final int dissolved;
  final int undissolved;

  @override
  State<ParticleView> createState() => _ParticleViewState();
}

class _ParticleViewState extends State<ParticleView>
    with SingleTickerProviderStateMixin {
  late final ParticleSim _sim = ParticleSim(random: Random(widget.seed));
  final ValueNotifier<int> _frame = ValueNotifier(0);
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  /// Reduced motion is on: draw one settled frame instead of animating.
  bool _still = false;
  bool _settled = false;

  @override
  void initState() {
    super.initState();
    if (widget.count case final count?) _sim.resize(count);
    _sim.setSugar(dissolved: widget.dissolved, undissolved: widget.undissolved);
    _ticker = createTicker((elapsed) {
      final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
      _last = elapsed;
      _sim.step(dt, widget.state, widget.energy);
      _frame.value++;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = MediaQuery.of(context).disableAnimations;
    if (_still) {
      _ticker.stop();
      _settled = false;
    } else if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  @override
  void didUpdateWidget(ParticleView old) {
    super.didUpdateWidget(old);
    if (widget.count case final count? when count != old.count) {
      _sim.resize(count);
    }
    if (widget.dissolved != old.dissolved ||
        widget.undissolved != old.undissolved) {
      _sim.setSugar(
        dissolved: widget.dissolved,
        undissolved: widget.undissolved,
      );
    }
    if (widget.state != old.state ||
        widget.energy != old.energy ||
        widget.count != old.count ||
        widget.dissolved != old.dissolved ||
        widget.undissolved != old.undissolved) {
      _settled = false;
    }
  }

  /// Runs the particles for a few seconds, so a still frame shows them as
  /// they settle: a liquid pooled, a gas spread through the box.
  void _settle() {
    for (var i = 0; i < 180; i++) {
      _sim.step(1 / 60, widget.state, widget.energy);
    }
    _settled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _frame.value++;
    });
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
      label: [
        'Particles in a ${widget.state.name}',
        if (widget.dissolved > 0) '${widget.dissolved} sugar dissolved',
        if (widget.undissolved > 0) '${widget.undissolved} sugar in a crystal',
      ].join(', '),
      child: TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: particleColor(widget.state)),
        duration: _still ? Duration.zero : const Duration(milliseconds: 500),
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
                if (_still && !_settled) _settle();
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
    final sugar = Paint()..color = ScienceColors.sugar;
    final shine = Paint()..color = Colors.white.withValues(alpha: 0.45);
    final scale = min(size.width / sim.width, size.height / sim.height);
    final origin = Offset(
      (size.width - sim.width * scale) / 2,
      size.height - sim.height * scale,
    );
    final r = ParticleSim.radius * scale;
    for (final p in sim.particles) {
      final at = origin + Offset(p.x, p.y) * scale;
      canvas.drawCircle(at, r, p.sugar ? sugar : body);
      canvas.drawCircle(at + Offset(-r * 0.35, -r * 0.35), r * 0.32, shine);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.color != color;
}
