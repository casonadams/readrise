import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// The shadow that lifts feedback above the page it covers.
const overlayShadow = [
  BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 4)),
];

/// An activity page whose [feedback] (a `FeedbackBanner`, an `AnswerPanel`)
/// slides up over the page's bottom edge instead of pushing the page around.
/// [page] gets the height the feedback covers, so a scrolling page can end
/// with that much room and nothing stays hidden under it.
class FeedbackLayout extends StatefulWidget {
  const FeedbackLayout({required this.page, this.feedback, super.key});

  final Widget Function(BuildContext context, double covered) page;

  /// Shown over the bottom of the page; null hides it. Give each message its
  /// own key so a new message slides in.
  final Widget? feedback;

  @override
  State<FeedbackLayout> createState() => _FeedbackLayoutState();
}

class _FeedbackLayoutState extends State<FeedbackLayout> {
  double _covered = 0;

  void _measured(Size size) {
    if (mounted && size.height != _covered) {
      setState(() => _covered = size.height);
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedback = widget.feedback;
    return Stack(
      children: [
        Positioned.fill(
          child: widget.page(context, feedback == null ? 0 : _covered),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.bottomCenter,
              children: [...previous, ?current],
            ),
            transitionBuilder: (child, animation) => SlideTransition(
              position: Tween(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
            child: feedback == null
                ? const SizedBox(width: double.infinity)
                : KeyedSubtree(
                    key: feedback.key ?? const ValueKey('feedback'),
                    child: Semantics(
                      liveRegion: true,
                      child: _SizeReporter(onSize: _measured, child: feedback),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _SizeReporter extends SingleChildRenderObjectWidget {
  const _SizeReporter({required this.onSize, super.child});

  final ValueChanged<Size> onSize;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSizeReporter(onSize);

  @override
  void updateRenderObject(BuildContext context, _RenderSizeReporter render) =>
      render.onSize = onSize;
}

class _RenderSizeReporter extends RenderProxyBox {
  _RenderSizeReporter(this.onSize);

  ValueChanged<Size> onSize;
  Size? _reported;

  @override
  void performLayout() {
    super.performLayout();
    if (size == _reported) return;
    final measured = _reported = size;
    SchedulerBinding.instance.addPostFrameCallback((_) => onSize(measured));
  }
}
