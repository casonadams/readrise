import 'dart:io';

import 'package:flutter/services.dart';

/// Loads Roboto, the app's font, from the Flutter SDK so text wraps in tests
/// as it does on screen. The default test font draws every glyph a full em
/// wide, which overstates how tall text gets.
Future<void> loadRoboto() async {
  final fonts =
      '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts';
  final loader = FontLoader('Roboto');
  for (final weight in ['Regular', 'Medium', 'Bold']) {
    loader.addFont(
      File('$fonts/Roboto-$weight.ttf')
          .readAsBytes()
          .then(ByteData.sublistView),
    );
  }
  await loader.load();
}
