import 'package:activity_kit/activity_kit.dart';
import 'package:flutter/material.dart';
import 'package:science_kit/science_kit.dart';

/// Water particles in the glass at the start.
const waterParticles = 30;

/// Particles that evaporate over the whole week.
const evaporatedInAWeek = 10;

/// Particles that have left the glass after [time] (0..1) of the week.
int evaporatedAt(double time) => (time * evaporatedInAWeek).round();

/// A glass of water with the air above it. As [time] passes, particles leave
/// the water's surface and fly in the air as a gas; the counts show that
/// every particle is still there.
class EvaporationView extends StatelessWidget {
  const EvaporationView(this.time, {super.key});

  final double time;

  @override
  Widget build(BuildContext context) {
    final inAir = evaporatedAt(time);
    final inGlass = waterParticles - inAir;
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: _Labelled(
            'Air',
            ParticleView(state: MatterState.gas, energy: 0.55, count: inAir),
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          flex: 2,
          child: _Labelled(
            'Glass',
            ParticleView(state: MatterState.liquid, count: inGlass),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            FactPill('In the glass: $inGlass', icon: Icons.local_drink_rounded),
            FactPill('In the air: $inAir', icon: Icons.air_rounded),
          ],
        ),
      ],
    );
  }
}

class _Labelled extends StatelessWidget {
  const _Labelled(this.label, this.child);

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(child: child),
      Positioned(
        left: 12,
        top: 6,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
    ],
  );
}
