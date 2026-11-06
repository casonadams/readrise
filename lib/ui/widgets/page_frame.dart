import 'package:flutter/material.dart';

/// Keeps content a comfortable width on wide screens (web, tablets).
class PageFrame extends StatelessWidget {
  const PageFrame({required this.child, this.maxWidth = 640, super.key});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}
