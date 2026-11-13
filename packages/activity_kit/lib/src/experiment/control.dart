import 'package:flutter/material.dart';

import '../experiment_slider.dart';

/// The one input of an experiment. [build] gets a null `onChanged` while the
/// experiment is not active, and may return an empty widget once the control
/// has no input left to give, so the view can use the space.
abstract interface class Control<T> {
  T get initial;

  Widget build(BuildContext context, T value, ValueChanged<T>? onChanged);
}

/// A slider from 0 to 1 between a [low] and a [high] icon.
class SliderControl implements Control<double> {
  const SliderControl({
    required this.label,
    required this.low,
    required this.high,
    this.color,
  });

  final String label;
  final IconData low;
  final IconData high;
  final Color? color;

  @override
  double get initial => 0;

  @override
  Widget build(
    BuildContext context,
    double value,
    ValueChanged<double>? onChanged,
  ) => ExperimentSlider(
    value: value,
    onChanged: onChanged,
    label: label,
    low: low,
    high: high,
    color: color,
  );
}

/// A button pressed up to [presses] times, with a dot filling per press. It
/// steps aside after the last press so the result can take its place.
class TapControl implements Control<int> {
  const TapControl({
    required this.label,
    required this.icon,
    required this.presses,
    this.color,
  });

  final String label;
  final IconData icon;
  final int presses;
  final Color? color;

  @override
  int get initial => 0;

  @override
  Widget build(BuildContext context, int value, ValueChanged<int>? onChanged) {
    if (value >= presses) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < presses; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 6),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < value
                  ? (color ?? scheme.primary)
                  : scheme.outlineVariant,
            ),
          ),
        const SizedBox(width: 10),
        FilledButton.icon(
          onPressed: onChanged == null ? null : () => onChanged(value + 1),
          style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
          icon: Icon(icon),
          label: Text(label),
        ),
      ],
    );
  }
}
