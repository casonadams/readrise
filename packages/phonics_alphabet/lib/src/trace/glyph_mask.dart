import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../letter.dart';

/// Paints [text] centred in [size]; the trace screen and [GlyphMask.render]
/// both use this so the outline and the mask always line up.
void paintGlyph(Canvas canvas, Size size, String text, Color color) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: letterFontFamily,
        package: letterFontPackage,
        fontWeight: FontWeight.w700,
        fontSize: size.height * 0.74,
        height: 1,
        color: color,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(
    canvas,
    Offset(
      (size.width - painter.width) / 2,
      (size.height - painter.height) / 2,
    ),
  );
  painter.dispose();
}

/// Which cells of a [size] x [size] grid over the unit square a glyph covers.
class GlyphMask {
  GlyphMask(this.size, this.cells) : assert(cells.length == size * size);

  /// A mask drawn from rows of text; '#' marks ink. Handy for tests.
  factory GlyphMask.fromRows(List<String> rows) => GlyphMask(rows.length, [
    for (final row in rows)
      for (final c in row.split('')) c == '#',
  ]);

  final int size;
  final List<bool> cells;

  int get inkCount => cells.where((c) => c).length;

  bool at(int x, int y) => cells[y * size + x];

  static Future<GlyphMask> render(String text, {int size = 96}) async {
    final recorder = ui.PictureRecorder();
    paintGlyph(
      Canvas(recorder),
      Size.square(size.toDouble()),
      text,
      const Color(0xFF000000),
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    final bytes = await image.toByteData();
    image.dispose();
    picture.dispose();
    return GlyphMask(size, [
      for (var i = 0; i < size * size; i++) bytes!.getUint8(i * 4 + 3) > 127,
    ]);
  }
}
