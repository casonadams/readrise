import 'package:activity_kit/activity_kit.dart';
import 'package:flutter/material.dart';

import 'matter_state.dart';
import 'particle_view.dart';
import 'fact_pill.dart';
import 'pop.dart';

const _energy = {
  MatterState.solid: 0.3,
  MatterState.liquid: 0.5,
  MatterState.gas: 0.7,
};

const _arrangement = {
  MatterState.solid: 'Packed tight',
  MatterState.liquid: 'Slide past each other',
  MatterState.gas: 'Fly far apart',
};

String _name(MatterState state) =>
    '${state.name[0].toUpperCase()}${state.name.substring(1)}';

/// Whether each state keeps its own shape and its own volume.
const _keeps = {
  MatterState.solid: (shape: true, volume: true),
  MatterState.liquid: (shape: false, volume: true),
  MatterState.gas: (shape: false, volume: false),
};

/// Solid, liquid and gas side by side; step 1 adds how each one's particles
/// are arranged.
Widget statesTrioScene(BuildContext context, int step) {
  final text = Theme.of(context).textTheme;
  return Center(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, state) in MatterState.values.indexed)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Pop(
                    visible: true,
                    delay: Duration(milliseconds: 150 * i),
                    child: AspectRatio(
                      aspectRatio: 0.6,
                      child: ParticleView(
                        state: state,
                        energy: _energy[state]!,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _name(state),
                    style: text.titleMedium?.copyWith(
                      color: particleColor(state),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 44,
                    child: Pop(
                      visible: step >= 1,
                      delay: Duration(milliseconds: 150 * i),
                      child: Text(
                        _arrangement[state]!,
                        style: text.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

/// One state's particles; from step 1 it shows whether the state keeps its
/// own shape and its own volume.
ExplainerScene stateScene(MatterState state) => (context, step) {
  final keeps = _keeps[state]!;
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Flexible(
        child: AspectRatio(
          aspectRatio: 1,
          child: ParticleView(state: state, energy: _energy[state]!),
        ),
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 10,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          Pop(
            visible: step >= 1,
            child: _keepsPill('Own shape', keeps: keeps.shape),
          ),
          Pop(
            visible: step >= 1,
            delay: const Duration(milliseconds: 200),
            child: _keepsPill('Own volume', keeps: keeps.volume),
          ),
        ],
      ),
    ],
  );
};

Widget _keepsPill(String label, {required bool keeps}) => FactPill(
  label,
  icon: keeps ? Icons.check_circle_rounded : Icons.cancel_rounded,
  color: keeps ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
);

/// Solid, liquid and gas as one story: all three, then each in turn, then
/// all three again with how their particles are arranged.
Widget statesScene(BuildContext context, int step) {
  final last = MatterState.values.length + 1;
  return AnimatedSwitcher(
    duration: const Duration(milliseconds: 350),
    child: KeyedSubtree(
      key: ValueKey(step == 0 || step == last ? 'trio$step' : step),
      child: step == 0 || step == last
          ? statesTrioScene(context, step == last ? 1 : 0)
          : stateScene(MatterState.values[step - 1])(context, 1),
    ),
  );
}
