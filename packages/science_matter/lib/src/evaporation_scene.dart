import 'package:flutter/material.dart';

import 'evaporation_view.dart';

/// How far through the week each explainer step shows.
const _times = [0.0, 0.3, 0.6, 1.0];

/// The glass of water from the experiment, a little further on each step.
Widget evaporationScene(BuildContext context, int step) =>
    TweenAnimationBuilder<double>(
      tween: Tween(end: _times[step]),
      duration: const Duration(milliseconds: 2500),
      curve: Curves.easeInOut,
      builder: (context, time, _) => EvaporationView(time),
    );
