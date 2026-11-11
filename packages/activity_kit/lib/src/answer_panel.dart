import 'package:flutter/material.dart';

/// Slides up once an answer is settled: what it means, then on.
class AnswerPanel extends StatelessWidget {
  const AnswerPanel({
    super.key,
    required this.title,
    required this.explanation,
    required this.onContinue,
    this.color = correctGreen,
    this.icon = Icons.check_circle_rounded,
    this.lead,
  });

  final String title;
  final String explanation;
  final VoidCallback onContinue;
  final Color color;
  final IconData icon;

  /// Shown between the title and the explanation.
  final Widget? lead;

  static const correctGreen = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Transform.translate(
        offset: Offset(0, 40 * (1 - t)),
        child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            color.withValues(alpha: 0.1),
            scheme.surfaceContainerLowest,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: text.titleLarge?.copyWith(color: color),
                  ),
                ),
              ],
            ),
            if (lead != null) ...[const SizedBox(height: 6), lead!],
            const SizedBox(height: 4),
            Text(explanation, style: text.bodyLarge?.copyWith(height: 1.35)),
            const SizedBox(height: 14),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: color),
              onPressed: onContinue,
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
