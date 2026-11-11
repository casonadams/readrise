import 'package:flutter/material.dart';

/// The one control of an experiment: a big slider between two icons.
class ExperimentSlider extends StatelessWidget {
  const ExperimentSlider({
    required this.value,
    required this.onChanged,
    required this.label,
    required this.low,
    required this.high,
    this.color,
    super.key,
  });

  final double value;
  final ValueChanged<double>? onChanged;
  final String label;
  final IconData low;
  final IconData high;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onChanged != null;
    final tint = enabled ? (color ?? scheme.primary) : scheme.outline;
    return Row(
      children: [
        Icon(low, color: tint.withValues(alpha: 0.6)),
        Expanded(
          child: Slider(
            value: value,
            onChanged: onChanged,
            activeColor: color,
            semanticFormatterCallback: (v) => '$label ${(v * 100).round()}%',
          ),
        ),
        Icon(high, color: tint, size: 28),
      ],
    );
  }
}
