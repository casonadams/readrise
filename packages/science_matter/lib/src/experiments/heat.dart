import 'package:activity_kit/activity_kit.dart';
import 'package:flutter/material.dart';

import '../matter_state.dart';
import '../particle_view.dart';

const _flame = Color(0xFFEF6C00);
const _stoveStart = 20.0;
const _stoveEnd = 110.0;

/// A sealed jar of gas over a flame. Turning up the heat speeds the
/// particles up while their size stays exactly the same.
const heatGasExperiment = ControlledExperiment<double>(
  control: SliderControl(
    label: 'Heat',
    low: Icons.ac_unit_rounded,
    high: Icons.local_fire_department_rounded,
    color: _flame,
  ),
  observed: _fullHeat,
  view: _HeatGasView.new,
);

/// A pot of water on a stove. Turning it up past 100 C boils the water: the
/// particles themselves fly off as a gas.
const stoveExperiment = ControlledExperiment<double>(
  control: SliderControl(
    label: 'Stove',
    low: Icons.ac_unit_rounded,
    high: Icons.local_fire_department_rounded,
    color: _flame,
  ),
  observed: _boiling,
  view: _StoveView.new,
);

bool _fullHeat(double heat) => heat >= 0.98;

double _celsius(double heat) => _stoveStart + (_stoveEnd - _stoveStart) * heat;

bool _boiling(double heat) => waterStateAt(_celsius(heat)) == MatterState.gas;

String _speedOf(double energy) => energy < 0.35
    ? 'Slow'
    : energy < 0.7
    ? 'Medium'
    : 'Fast';

class _HeatGasView extends StatelessWidget {
  const _HeatGasView(this.heat);

  final double heat;

  double get _energy => 0.05 + 0.95 * heat;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: ParticleView(state: MatterState.gas, energy: _energy),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            FactPill(
              'Speed: ${_speedOf(_energy)}',
              icon: Icons.speed_rounded,
              color: Color.lerp(Colors.blue, Colors.red, heat),
            ),
            FactPill(
              'Particle size: same',
              icon: Icons.circle,
              color: scheme.primary,
            ),
          ],
        ),
      ],
    );
  }
}

class _StoveView extends StatelessWidget {
  const _StoveView(this.heat);

  final double heat;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final celsius = _celsius(heat);
    final state = waterStateAt(celsius);
    return Stack(
      children: [
        Positioned.fill(
          child: ParticleView(state: state, energy: energyAt(celsius)),
        ),
        Positioned(
          left: 12,
          top: 8,
          child: Text(
            '${celsius.round()}\u00B0C',
            style: text.headlineSmall?.copyWith(
              color: Color.lerp(Colors.blue, Colors.red, heat),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 8,
          child: Center(
            child: Pop(
              visible: state == MatterState.gas,
              child: const FactPill(
                'The water itself is now a gas',
                icon: Icons.water_drop_rounded,
                color: Color(0xFF7B1FA2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
