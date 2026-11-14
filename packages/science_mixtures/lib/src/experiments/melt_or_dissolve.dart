import 'package:activity_kit/activity_kit.dart';
import 'package:flutter/material.dart';
import 'package:science_kit/science_kit.dart';

import '../glass_view.dart';

/// An ice cube in a warm room beside a sugar cube in water. As time passes
/// the ice turns liquid but stays only water, while the sugar spreads out
/// between water particles.
const meltOrDissolveExperiment = ControlledExperiment<double>(
  control: SliderControl(
    label: 'Time',
    low: Icons.timer_outlined,
    high: Icons.timer_rounded,
  ),
  observed: _done,
  view: MeltOrDissolveView.new,
);

bool _done(double time) => time >= 0.98;

/// The ice and the sugar [time] (0..1) of the way through.
class MeltOrDissolveView extends StatelessWidget {
  const MeltOrDissolveView(this.time, {super.key});

  final double time;

  @override
  Widget build(BuildContext context) {
    final celsius = -10 + 30 * time;
    final dissolved = dissolvedAt(time);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _Side(
            title: 'Ice in a warm room',
            particles: ParticleView(
              state: waterStateAt(celsius),
              energy: energyAt(celsius),
            ),
            fact: const FactPill('Only water', icon: Icons.water_drop_rounded),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Side(
            title: 'Sugar in water',
            particles: ParticleView(
              state: MatterState.liquid,
              dissolved: dissolved,
              undissolved: sugarCube - dissolved,
            ),
            fact: const FactPill(
              'Water + sugar',
              icon: Icons.grain_rounded,
              color: ScienceColors.sugar,
            ),
          ),
        ),
      ],
    );
  }
}

class _Side extends StatelessWidget {
  const _Side({
    required this.title,
    required this.particles,
    required this.fact,
  });

  final String title;
  final Widget particles;
  final Widget fact;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        title,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelLarge,
      ),
      const SizedBox(height: 6),
      Expanded(child: particles),
      const SizedBox(height: 8),
      FittedBox(fit: BoxFit.scaleDown, child: fact),
    ],
  );
}
