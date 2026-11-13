import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readrise/plugins.dart';
import 'package:readrise/ui/theme.dart';

double contrast(Color a, Color b) {
  final hi = max(a.computeLuminance(), b.computeLuminance());
  final lo = min(a.computeLuminance(), b.computeLuminance());
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  test('a subject uses its own colour, readable with its text colour', () {
    for (final subject in {for (final c in installedCourses()) c.subject}) {
      final scheme = subjectTheme(subject).colorScheme;
      expect(scheme.primary, subject.color);
      expect(
        contrast(scheme.onPrimary, scheme.primary),
        greaterThanOrEqualTo(4.5),
      );
    }
  });

  test('onColor reaches AA contrast across the whole colour wheel', () {
    for (var hue = 0.0; hue < 360; hue += 15) {
      for (final lightness in [0.3, 0.5, 0.7]) {
        final c = HSLColor.fromAHSL(1, hue, 0.9, lightness).toColor();
        expect(
          contrast(onColor(c), c),
          greaterThanOrEqualTo(4.5),
          reason: 'hue $hue lightness $lightness',
        );
      }
    }
  });

  test('dark backgrounds get white text and light ones get black', () {
    expect(onColor(const Color(0xFF102040)), Colors.white);
    expect(onColor(const Color(0xFFFFF3C4)), Colors.black);
  });
}
