import 'package:flutter/material.dart';

import 'experiments/melt_or_dissolve.dart';
import 'experiments/spoons.dart';
import 'experiments/stir.dart';

/// Shows [view] at [frames][step], easing between steps.
Widget _eased(
  List<double> frames,
  int step,
  Widget Function(double value) view,
) => TweenAnimationBuilder<double>(
  tween: Tween(end: frames[step]),
  duration: const Duration(milliseconds: 2500),
  curve: Curves.easeInOut,
  builder: (context, value, _) => view(value),
);

/// The sugar cube from the experiment, a little more dissolved each step.
Widget dissolvingScene(BuildContext context, int step) =>
    _eased(const [0, 0.4, 1, 1], step, DissolvingView.new);

/// Ice and sugar side by side: as they start, ice melted, sugar dissolved.
Widget meltOrDissolveScene(BuildContext context, int step) =>
    _eased(const [0, 0.5, 1, 1], step, MeltOrDissolveView.new);

/// The glass on the scale, dissolving while the reading stays the same.
Widget massScene(BuildContext context, int step) =>
    _eased(const [0, 0.5, 1, 1], step, MassView.new);

const _spoonsAt = [1, 3, 5, 6, 6];

/// The glass filling up with sugar, spoon by spoon.
Widget spoonsScene(BuildContext context, int step) =>
    SpoonsView(_spoonsAt[step]);
