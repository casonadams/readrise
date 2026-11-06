import 'dart:io';

import 'package:flutter/services.dart';
import 'package:phonics_alphabet/src/letter.dart';

/// Loads the bundled Andika font so tests draw real letter shapes instead of
/// the test font's boxes. Run from the package directory (flutter test does).
Future<void> loadAndika() async {
  final bytes = File('assets/fonts/Andika-Bold.ttf').readAsBytesSync();
  final loader = FontLoader('packages/$letterFontPackage/$letterFontFamily')
    ..addFont(Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)));
  await loader.load();
}
