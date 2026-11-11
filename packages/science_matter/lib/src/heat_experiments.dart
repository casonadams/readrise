import 'package:activity_kit/activity_kit.dart';
import 'package:flutter/material.dart';

import 'experiment_slider.dart';
import 'fact_pill.dart';
import 'matter_state.dart';
import 'particle_view.dart';
import 'pop.dart';

const _flame = Color(0xFFEF6C00);

/// A sealed jar of gas over a flame. Turning up the heat speeds the
/// particles up while their size stays exactly the same.
const Experiment heatGasExperiment = _heatGasExperiment;

/// A pot of water on a stove. Turning it up past 100 C boils the water: the
/// particles themselves fly off as a gas.
const Experiment stoveExperiment = _stoveExperiment;

Widget _heatGasExperiment(
  BuildContext context,
  bool active,
  VoidCallback onObserved,
) => _HeatGas(active: active, onObserved: onObserved);

Widget _stoveExperiment(
  BuildContext context,
  bool active,
  VoidCallback onObserved,
) => _Stove(active: active, onObserved: onObserved);

String _speedOf(double energy) => energy < 0.35
    ? 'Slow'
    : energy < 0.7
    ? 'Medium'
    : 'Fast';

class _HeatGas extends StatefulWidget {
  const _HeatGas({required this.active, required this.onObserved});

  final bool active;
  final VoidCallback onObserved;

  @override
  State<_HeatGas> createState() => _HeatGasState();
}

class _HeatGasState extends State<_HeatGas> {
  double _heat = 0;
  bool _reported = false;

  double get _energy => 0.05 + 0.95 * _heat;

  void _setHeat(double heat) {
    setState(() => _heat = heat);
    if (heat >= 0.98 && !_reported) {
      _reported = true;
      widget.onObserved();
    }
  }

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
              color: Color.lerp(Colors.blue, Colors.red, _heat),
            ),
            FactPill(
              'Particle size: same',
              icon: Icons.circle,
              color: scheme.primary,
            ),
          ],
        ),
        ExperimentSlider(
          value: _heat,
          onChanged: widget.active ? _setHeat : null,
          label: 'Heat',
          low: Icons.ac_unit_rounded,
          high: Icons.local_fire_department_rounded,
          color: _flame,
        ),
      ],
    );
  }
}

class _Stove extends StatefulWidget {
  const _Stove({required this.active, required this.onObserved});

  final bool active;
  final VoidCallback onObserved;

  @override
  State<_Stove> createState() => _StoveState();
}

class _StoveState extends State<_Stove> {
  static const _start = 20.0;
  static const _end = 110.0;
  double _celsius = _start;
  bool _reported = false;

  MatterState get _state => waterStateAt(_celsius);

  void _setHeat(double heat) {
    setState(() => _celsius = _start + (_end - _start) * heat);
    if (_state == MatterState.gas && !_reported) {
      _reported = true;
      widget.onObserved();
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: ParticleView(state: _state, energy: energyAt(_celsius)),
              ),
              Positioned(
                left: 12,
                top: 8,
                child: Text(
                  '${_celsius.round()}\u00B0C',
                  style: text.headlineSmall?.copyWith(
                    color: Color.lerp(Colors.blue, Colors.red, _heatFraction),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 8,
                child: Center(
                  child: Pop(
                    visible: _state == MatterState.gas,
                    child: const FactPill(
                      'The water itself is now a gas',
                      icon: Icons.water_drop_rounded,
                      color: Color(0xFF7B1FA2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        ExperimentSlider(
          value: _heatFraction,
          onChanged: widget.active ? _setHeat : null,
          label: 'Stove',
          low: Icons.ac_unit_rounded,
          high: Icons.local_fire_department_rounded,
          color: _flame,
        ),
      ],
    );
  }

  double get _heatFraction => (_celsius - _start) / (_end - _start);
}
