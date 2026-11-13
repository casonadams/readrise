import 'package:activity_kit/activity_kit.dart';
import 'package:flutter/material.dart';
import 'package:science_kit/science_kit.dart';

/// Step 0: loose atoms drift. Step 1: they join into a molecule. Step 2: the
/// atoms are counted. Step 3: the formula appears. Step 4: the charges appear.
Widget waterMoleculeScene(BuildContext context, int step) => Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Flexible(
      child: FittedBox(
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: step >= 1 ? 1 : 0),
          duration: const Duration(milliseconds: 1100),
          curve: Curves.easeInOutBack,
          builder: (context, join, _) =>
              WaterMolecule(join: join, charged: step >= 4),
        ),
      ),
    ),
    const SizedBox(height: 16),
    Pop(
      visible: step >= 2,
      child: const Wrap(
        spacing: 10,
        children: [
          FactPill('2 hydrogen', color: Color(0xFF616161)),
          FactPill('1 oxygen', color: ScienceColors.oxygen),
        ],
      ),
    ),
    const SizedBox(height: 8),
    Pop(
      visible: step >= 3,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'H\u2082',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            const TextSpan(
              text: 'O',
              style: TextStyle(color: ScienceColors.oxygen),
            ),
          ],
        ),
        style: Theme.of(context).textTheme.displaySmall
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
    ),
  ],
);
