import 'package:activity_kit/activity_kit.dart';
import 'package:flutter/material.dart';
import 'package:science_kit/science_kit.dart';

/// Sugar particles in one sugar cube.
const sugarCube = 12;

/// Sugar cube particles dissolved after stirring [stir] (0..1) of the way.
int dissolvedAt(double stir) => (stir * sugarCube).round();

/// A glass of water seen at particle size: [dissolved] sugar particles
/// spread through it, [undissolved] ones still solid on the floor, and one
/// row of [facts] underneath. [banner] pops up inside the glass when
/// [bannerShown], so it never takes height from the particles.
class GlassView extends StatelessWidget {
  const GlassView({
    required this.dissolved,
    required this.undissolved,
    required this.facts,
    this.banner,
    this.bannerShown = false,
    super.key,
  });

  final int dissolved;
  final int undissolved;
  final List<Widget> facts;
  final Widget? banner;
  final bool bannerShown;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: Stack(
          children: [
            Positioned.fill(
              child: ParticleView(
                state: MatterState.liquid,
                dissolved: dissolved,
                undissolved: undissolved,
              ),
            ),
            if (banner case final banner?)
              Positioned(
                left: 0,
                right: 0,
                top: 10,
                child: Center(
                  child: Pop(visible: bannerShown, child: banner),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          children: [
            for (final (i, fact) in facts.indexed) ...[
              if (i > 0) const SizedBox(width: 8),
              fact,
            ],
          ],
        ),
      ),
    ],
  );
}
