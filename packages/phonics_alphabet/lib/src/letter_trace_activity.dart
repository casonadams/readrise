import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

import 'letter.dart';
import 'trace/glyph_mask.dart';
import 'trace/trace_checker.dart';

typedef GlyphMaskLoader = Future<GlyphMask> Function(String glyph);

/// Trace the capital letter, then the small one, with a finger. Tracing is
/// never marked wrong: [Clear] starts over and [Skip] moves on without credit.
class LetterTraceActivity implements ActivityPlugin {
  const LetterTraceActivity(
    this.letter, {
    this.maskLoader = GlyphMask.render,
    this.xpPerGlyph = 5,
  });

  final Letter letter;
  final GlyphMaskLoader maskLoader;
  final int xpPerGlyph;

  @override
  Widget build(BuildContext context, ActivityHost host) =>
      _TraceView(activity: this, host: host);
}

class _TraceView extends StatefulWidget {
  const _TraceView({required this.activity, required this.host});

  final LetterTraceActivity activity;
  final ActivityHost host;

  @override
  State<_TraceView> createState() => _TraceViewState();
}

class _TraceViewState extends State<_TraceView> {
  late final List<(String glyph, String name)> _steps = [
    (widget.activity.letter.upper, 'big'),
    (widget.activity.letter.char, 'small'),
  ];
  int _step = 0;
  int _traced = 0;
  TraceChecker? _checker;
  List<List<Offset>> _strokes = [];
  bool _done = false;

  String get _glyph => _steps[_step].$1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final glyph = _glyph;
    final mask = await widget.activity.maskLoader(glyph);
    if (!mounted || glyph != _glyph) return;
    setState(() {
      _checker = TraceChecker(mask);
      _strokes = [];
      _done = false;
    });
  }

  void _clear() => setState(() {
    _checker?.reset();
    _strokes = [];
    _done = false;
  });

  void _advance({required bool traced}) {
    if (traced) _traced++;
    if (_step + 1 == _steps.length) {
      widget.host.complete(
        ActivityResult(xp: _traced * widget.activity.xpPerGlyph),
      );
      return;
    }
    setState(() {
      _step++;
      _checker = null;
    });
    _load();
  }

  Offset _unit(Offset local, double side) =>
      Offset(local.dx / side, local.dy / side);

  void _start(Offset local, double side) {
    if (_done || _checker == null) return;
    final p = _unit(local, side);
    setState(() {
      _checker!.startStroke(p);
      _strokes.add([p]);
    });
  }

  void _update(Offset local, double side) {
    if (_done || _checker == null || _strokes.isEmpty) return;
    final p = _unit(local, side);
    setState(() {
      _checker!.extendStroke(p);
      _strokes.last.add(p);
      if (_checker!.isComplete) {
        _done = true;
        HapticFeedback.mediumImpact();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final name = _steps[_step].$2;
    final last = _step + 1 == _steps.length;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Trace the $name letter',
            textAlign: TextAlign.center,
            style: text.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Draw over the grey letter with your finger.',
            textAlign: TextAlign.center,
            style: text.bodyMedium,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: LayoutBuilder(
                  builder: (context, box) {
                    final side = box.maxWidth;
                    return Semantics(
                      label:
                          'Drawing area. Trace the $name letter $_glyph '
                          'with your finger, or use Skip.',
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: _done
                                ? Colors.green.shade400
                                : scheme.outlineVariant,
                            width: 3,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: _checker == null
                              ? const Center(child: CircularProgressIndicator())
                              : GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onPanStart: (d) =>
                                      _start(d.localPosition, side),
                                  onPanUpdate: (d) =>
                                      _update(d.localPosition, side),
                                  onPanEnd: (_) => _checker?.endStroke(),
                                  child: CustomPaint(
                                    key: const Key('trace-canvas'),
                                    size: Size.square(side),
                                    painter: _TracePainter(
                                      glyph: _glyph,
                                      strokes: _strokes,
                                      outline: _done
                                          ? Colors.green.shade200
                                          : scheme.outlineVariant,
                                      ink: _done
                                          ? Colors.green.shade600
                                          : scheme.primary,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 56,
            child: _done
                ? FilledButton(
                    onPressed: () => _advance(traced: true),
                    child: Text(last ? 'Great! Continue' : 'Great! Next'),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _strokes.isEmpty ? null : _clear,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Clear'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextButton(
                          onPressed: _checker == null
                              ? null
                              : () => _advance(traced: false),
                          child: const Text('Skip'),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _TracePainter extends CustomPainter {
  const _TracePainter({
    required this.glyph,
    required this.strokes,
    required this.outline,
    required this.ink,
  });

  final String glyph;
  final List<List<Offset>> strokes;
  final Color outline;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    paintGlyph(canvas, size, glyph, outline);
    final paint = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = size.width * 0.07;
    for (final stroke in strokes) {
      if (stroke.length == 1) {
        canvas.drawCircle(
          stroke.first.scale(size.width, size.height),
          paint.strokeWidth / 2,
          Paint()..color = ink,
        );
        continue;
      }
      final path = Path()
        ..moveTo(stroke.first.dx * size.width, stroke.first.dy * size.height);
      for (final p in stroke.skip(1)) {
        path.lineTo(p.dx * size.width, p.dy * size.height);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_TracePainter old) => true;
}
