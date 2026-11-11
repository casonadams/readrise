import 'package:flutter/material.dart';

enum FeedbackKind { correct, wrong, hint }

/// A short coloured note to the learner: what went right, what went wrong,
/// or a hint.
class FeedbackBanner extends StatelessWidget {
  const FeedbackBanner({
    required this.kind,
    required this.message,
    this.title,
    super.key,
  });

  final FeedbackKind kind;
  final String message;
  final String? title;

  static const _green = Color(0xFF2E7D32);
  static const _amber = Color(0xFFB26A00);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final (color, icon) = switch (kind) {
      FeedbackKind.correct => (_green, Icons.check_circle_rounded),
      FeedbackKind.wrong => (scheme.error, Icons.info_rounded),
      FeedbackKind.hint => (_amber, Icons.lightbulb_rounded),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          color.withValues(alpha: 0.1),
          scheme.surfaceContainerLowest,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(title!, style: text.titleMedium?.copyWith(color: color)),
                Text(message, style: text.bodyLarge?.copyWith(height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
