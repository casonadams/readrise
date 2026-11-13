import 'dart:async';

import 'package:flutter/widgets.dart';

/// Scales and fades [child] in after [delay] once [visible] turns true, and
/// out again when it turns false.
class Pop extends StatefulWidget {
  const Pop({
    super.key,
    required this.visible,
    required this.child,
    this.delay = Duration.zero,
  });

  final bool visible;
  final Duration delay;
  final Widget child;

  @override
  State<Pop> createState() => _PopState();
}

class _PopState extends State<Pop> {
  Timer? _timer;
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(Pop old) {
    super.didUpdateWidget(old);
    if (old.visible != widget.visible) _sync();
  }

  void _sync() {
    _timer?.cancel();
    if (!widget.visible) {
      _shown = false;
    } else {
      _timer = Timer(widget.delay, () => setState(() => _shown = true));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedSlide(
    offset: _shown ? Offset.zero : const Offset(0, 0.2),
    curve: Curves.easeOutCubic,
    duration: const Duration(milliseconds: 400),
    child: AnimatedScale(
      scale: _shown ? 1 : 0.7,
      curve: Curves.easeOutBack,
      duration: const Duration(milliseconds: 400),
      child: AnimatedOpacity(
        opacity: _shown ? 1 : 0,
        duration: const Duration(milliseconds: 250),
        child: widget.child,
      ),
    ),
  );
}
