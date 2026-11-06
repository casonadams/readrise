import 'package:flutter/material.dart';

/// A letter pair such as "Mm" on one line; shrinks instead of wrapping.
class LetterText extends StatelessWidget {
  const LetterText(this.text, {required this.style, super.key});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(text, style: style, maxLines: 1, softWrap: false),
  );
}
