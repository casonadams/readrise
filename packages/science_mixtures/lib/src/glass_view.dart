import 'package:flutter/material.dart';
import 'package:science_kit/science_kit.dart';

/// Sugar particles in one sugar cube.
const sugarCube = 12;

/// Sugar cube particles dissolved after stirring [stir] (0..1) of the way.
int dissolvedAt(double stir) => (stir * sugarCube).round();

/// A glass of water seen at particle size: [dissolved] sugar particles
/// spread through it, [undissolved] ones still solid on the floor, and
/// [facts] about it underneath.
class GlassView extends StatelessWidget {
  const GlassView({
    required this.dissolved,
    required this.undissolved,
    required this.facts,
    super.key,
  });

  final int dissolved;
  final int undissolved;
  final List<Widget> facts;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: ParticleView(
          state: MatterState.liquid,
          dissolved: dissolved,
          undissolved: undissolved,
        ),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 6,
        alignment: WrapAlignment.center,
        children: facts,
      ),
    ],
  );
}
