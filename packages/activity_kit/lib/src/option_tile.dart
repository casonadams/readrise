import 'package:flutter/material.dart';

/// How a choice looks: still open, picked (no verdict yet), crossed out,
/// marked right, or faded once another choice won.
enum OptionState { open, picked, wrong, correct, dimmed }

/// A lettered answer choice.
class OptionTile extends StatelessWidget {
  const OptionTile({
    super.key,
    required this.letter,
    required this.label,
    required this.state,
    required this.onTap,
  });

  final String letter;
  final String label;
  final OptionState state;
  final VoidCallback onTap;

  static const _green = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final accent = switch (state) {
      OptionState.correct => _green,
      OptionState.wrong => scheme.error,
      _ => scheme.primary,
    };
    final marked =
        state == OptionState.correct ||
        state == OptionState.wrong ||
        state == OptionState.picked;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: state == OptionState.dimmed || state == OptionState.wrong
          ? 0.55
          : 1,
      child: Material(
        color: marked
            ? Color.alphaBlend(
                accent.withValues(alpha: 0.12),
                scheme.surfaceContainerLowest,
              )
            : scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: marked ? accent : scheme.outlineVariant,
            width: 2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: state == OptionState.open ? onTap : null,
          child: Semantics(
            button: true,
            enabled: state == OptionState.open,
            label: switch (state) {
              OptionState.correct => '$label, correct',
              OptionState.picked => '$label, your pick',
              OptionState.wrong => '$label, wrong',
              _ => label,
            },
            excludeSemantics: true,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 60),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: marked ? accent : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: marked ? accent : scheme.outlineVariant,
                          width: 2,
                        ),
                      ),
                      child: switch (state) {
                        OptionState.correct => const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        OptionState.wrong => const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        _ => Text(
                          letter,
                          style: text.labelLarge?.copyWith(
                            color: state == OptionState.picked
                                ? Colors.white
                                : scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: text.titleMedium?.copyWith(
                          decoration: state == OptionState.wrong
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
