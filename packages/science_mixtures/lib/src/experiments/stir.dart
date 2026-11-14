import 'package:activity_kit/activity_kit.dart';
import 'package:flutter/material.dart';
import 'package:science_kit/science_kit.dart';

import '../glass_view.dart';

const _stir = SliderControl(
  label: 'Stir',
  low: Icons.pause_circle_outline_rounded,
  high: Icons.autorenew_rounded,
  color: ScienceColors.sugar,
);

bool _allDissolved(double stir) => dissolvedAt(stir) == sugarCube;

/// A sugar cube in water. Stirring knocks its particles loose until all of
/// them are spread through the water, and none are missing.
const dissolvingExperiment = ControlledExperiment<double>(
  control: _stir,
  observed: _allDissolved,
  view: DissolvingView.new,
);

/// The same glass on a scale: the reading never changes while it dissolves.
const massExperiment = ControlledExperiment<double>(
  control: _stir,
  observed: _allDissolved,
  view: MassView.new,
);

/// A sugar cube [stir] (0..1) of the way to dissolved.
class DissolvingView extends StatelessWidget {
  const DissolvingView(this.stir, {super.key});

  final double stir;

  @override
  Widget build(BuildContext context) {
    final dissolved = dissolvedAt(stir);
    return GlassView(
      dissolved: dissolved,
      undissolved: sugarCube - dissolved,
      facts: [
        const FactPill(
          'Sugar particles: $sugarCube',
          icon: Icons.grain_rounded,
          color: ScienceColors.sugar,
        ),
        FactPill(
          'Still in the cube: ${sugarCube - dissolved}',
          icon: Icons.square_rounded,
        ),
        Pop(
          visible: dissolved == sugarCube,
          child: const FactPill(
            'Hidden, not gone',
            icon: Icons.visibility_off_rounded,
            color: Color(0xFF7B1FA2),
          ),
        ),
      ],
    );
  }
}

/// 100 g of water and a 10 g sugar cube on a scale, [stir] (0..1) of the
/// way to dissolved.
class MassView extends StatelessWidget {
  const MassView(this.stir, {super.key});

  final double stir;

  @override
  Widget build(BuildContext context) {
    final dissolved = dissolvedAt(stir);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Semantics(
          label: 'Scale reads 110 grams',
          excludeSemantics: true,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.inverseSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.scale_rounded, color: scheme.onInverseSurface),
                const SizedBox(width: 10),
                Text(
                  '110 g',
                  style: text.headlineSmall?.copyWith(
                    color: scheme.onInverseSurface,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GlassView(
            dissolved: dissolved,
            undissolved: sugarCube - dissolved,
            facts: [
              const FactPill('Water: 100 g', icon: Icons.water_drop_rounded),
              const FactPill(
                'Sugar: 10 g',
                icon: Icons.grain_rounded,
                color: ScienceColors.sugar,
              ),
              Pop(
                visible: dissolved == sugarCube,
                child: const FactPill(
                  'No particle left the glass',
                  icon: Icons.check_circle_rounded,
                  color: Color(0xFF7B1FA2),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
