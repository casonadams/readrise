import 'package:activity_kit/activity_kit.dart';
import 'package:flutter/material.dart';

import '../evaporation_view.dart';

/// A glass of water in a cool room. Letting a week pass shows particles
/// leaving the surface as a gas, without boiling, and none disappearing.
const evaporationExperiment = ControlledExperiment<double>(
  control: SliderControl(
    label: 'Time',
    low: Icons.today_rounded,
    high: Icons.date_range_rounded,
  ),
  observed: _weekGone,
  view: EvaporationView.new,
);

bool _weekGone(double time) => evaporatedAt(time) == evaporatedInAWeek;
