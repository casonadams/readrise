import 'package:flutter/material.dart';

/// A short fact the scene has just shown, with an optional leading icon.
class FactPill extends StatelessWidget {
  const FactPill(this.label, {this.icon, this.color, super.key});

  final String label;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = color ?? scheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          tint.withValues(alpha: 0.12),
          scheme.surfaceContainerLowest,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tint.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: tint),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: scheme.onSurface),
          ),
        ],
      ),
    );
  }
}
