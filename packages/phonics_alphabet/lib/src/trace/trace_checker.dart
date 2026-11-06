import 'dart:math';
import 'dart:ui' show Offset;

import 'glyph_mask.dart';

/// Decides whether strokes drawn over a letter trace it. Points are in the
/// unit square, like the mask.
///
/// A trace is complete when enough of the letter's ink has been covered and
/// most of the drawing stayed near the letter, so scribbling everywhere does
/// not count.
class TraceChecker {
  TraceChecker(
    this.mask, {
    this.brushRadius = 0.05,
    this.tolerance = 0.07,
    this.neededCoverage = 0.7,
    this.neededAccuracy = 0.65,
  }) : _near = _dilate(mask, (tolerance * mask.size).ceil()),
       _covered = List.filled(mask.size * mask.size, false),
       _ink = mask.inkCount;

  final GlyphMask mask;
  final double brushRadius;
  final double tolerance;
  final double neededCoverage;
  final double neededAccuracy;

  final List<bool> _near;
  final List<bool> _covered;
  final int _ink;
  int _coveredInk = 0;
  int _onTrack = 0;
  int _total = 0;
  Offset? _last;

  double get coverage => _ink == 0 ? 0 : _coveredInk / _ink;
  double get accuracy => _total == 0 ? 0 : _onTrack / _total;
  bool get isComplete =>
      _ink > 0 && coverage >= neededCoverage && accuracy >= neededAccuracy;

  void startStroke(Offset p) {
    _last = null;
    extendStroke(p);
  }

  /// Adds [p], filling in the path from the previous point so a fast finger
  /// does not leave gaps.
  void extendStroke(Offset p) {
    final from = _last;
    _last = p;
    if (from == null) {
      _mark(p);
      return;
    }
    final steps = max(1, ((p - from).distance * mask.size).ceil());
    for (var i = 1; i <= steps; i++) {
      _mark(Offset.lerp(from, p, i / steps)!);
    }
  }

  void endStroke() => _last = null;

  void reset() {
    _covered.fillRange(0, _covered.length, false);
    _coveredInk = 0;
    _onTrack = 0;
    _total = 0;
    _last = null;
  }

  void _mark(Offset p) {
    final n = mask.size;
    final cx = (p.dx * n).floor();
    final cy = (p.dy * n).floor();
    _total++;
    if (cx >= 0 && cx < n && cy >= 0 && cy < n && _near[cy * n + cx]) {
      _onTrack++;
    }
    final r = (brushRadius * n).ceil();
    for (var y = max(0, cy - r); y <= min(n - 1, cy + r); y++) {
      for (var x = max(0, cx - r); x <= min(n - 1, cx + r); x++) {
        final i = y * n + x;
        if (_covered[i] || !mask.cells[i]) continue;
        if ((x - cx) * (x - cx) + (y - cy) * (y - cy) <= r * r) {
          _covered[i] = true;
          _coveredInk++;
        }
      }
    }
  }

  static List<bool> _dilate(GlyphMask mask, int radius) {
    final n = mask.size;
    final out = List.filled(n * n, false);
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        if (!mask.cells[y * n + x]) continue;
        for (var dy = -radius; dy <= radius; dy++) {
          for (var dx = -radius; dx <= radius; dx++) {
            final nx = x + dx;
            final ny = y + dy;
            if (nx < 0 || ny < 0 || nx >= n || ny >= n) continue;
            if (dx * dx + dy * dy <= radius * radius) out[ny * n + nx] = true;
          }
        }
      }
    }
    return out;
  }
}
