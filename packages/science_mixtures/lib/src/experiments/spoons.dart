import 'package:activity_kit/activity_kit.dart';
import 'package:flutter/material.dart';
import 'package:science_kit/science_kit.dart';

import '../glass_view.dart';

/// Sugar particles in one spoonful.
const _perSpoon = 4;

/// Spoonfuls the glass of water can dissolve.
const _fits = 3;

const _spoons = 6;

/// Spoon after spoon of sugar into one glass of water. The first spoons
/// dissolve; once the water is full, the rest stays solid at the bottom.
const spoonsExperiment = ControlledExperiment<int>(
  control: TapControl(
    label: 'Add a spoon',
    icon: Icons.add_circle_outline_rounded,
    presses: _spoons,
    color: ScienceColors.sugar,
  ),
  observed: _allAdded,
  view: SpoonsView.new,
  settle: Duration(milliseconds: 1200),
);

bool _allAdded(int spoons) => spoons >= _spoons;

/// The glass after [spoons] spoonfuls of sugar.
class SpoonsView extends StatelessWidget {
  const SpoonsView(this.spoons, {super.key});

  final int spoons;

  @override
  Widget build(BuildContext context) {
    final dissolvedSpoons = spoons.clamp(0, _fits);
    final full = spoons > _fits;
    return GlassView(
      dissolved: dissolvedSpoons * _perSpoon,
      undissolved: (spoons - dissolvedSpoons) * _perSpoon,
      facts: [
        FactPill(
          'Spoons added: $spoons',
          icon: Icons.add_circle_outline_rounded,
          color: ScienceColors.sugar,
        ),
        FactPill('Dissolved: $dissolvedSpoons', icon: Icons.water_drop_rounded),
        Pop(
          visible: full,
          child: const FactPill(
            'Full: the rest stays at the bottom',
            icon: Icons.block_rounded,
            color: Color(0xFF7B1FA2),
          ),
        ),
      ],
    );
  }
}
