import 'package:flutter/material.dart';

/// What kind of moment an activity is, so the learner always knows whether
/// they are guessing, learning, practising, or proving it.
enum ActivityKind {
  warmUp('Warm-up', Icons.bolt_rounded, Color(0xFFF57C00)),
  predict('Predict', Icons.psychology_alt_rounded, Color(0xFF7B1FA2)),
  sort('Sort it', Icons.dashboard_customize_rounded, Color(0xFF00897B)),
  check('Check', Icons.fact_check_rounded, Color(0xFF1E88E5)),
  whoIsRight("Who's right?", Icons.forum_rounded, Color(0xFFD81B60));

  const ActivityKind(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

/// The kind badge on the left and progress on the right.
class ActivityHeader extends StatelessWidget {
  const ActivityHeader({required this.kind, this.trailing, super.key});

  final ActivityKind kind;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(8, 5, 12, 5),
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              kind.color.withValues(alpha: 0.14),
              scheme.surfaceContainerLowest,
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(kind.icon, size: 18, color: kind.color),
              const SizedBox(width: 6),
              Text(
                kind.label,
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(color: kind.color, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: FittedBox(fit: BoxFit.scaleDown, child: trailing),
          ),
        ),
      ],
    );
  }
}
