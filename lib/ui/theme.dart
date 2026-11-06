import 'package:flutter/material.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

const _brand = Color(0xFF6C4CF1);

ThemeData appTheme() => _build(ColorScheme.fromSeed(seedColor: _brand));

/// A subject's colour carries through its path, lessons and activities.
ThemeData subjectTheme(Subject subject) => _build(
  ColorScheme.fromSeed(
    seedColor: subject.color,
    dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
  ).copyWith(primary: subject.color, onPrimary: onColor(subject.color)),
);

/// Black or white, whichever reads better on [background].
Color onColor(Color background) {
  final l = background.computeLuminance();
  final whiteContrast = 1.05 / (l + 0.05);
  final blackContrast = (l + 0.05) / 0.05;
  return whiteContrast >= blackContrast ? Colors.white : Colors.black;
}

ThemeData _build(ColorScheme scheme) {
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  final text = base.textTheme;
  return base.copyWith(
    scaffoldBackgroundColor: Color.alphaBlend(
      scheme.primary.withValues(alpha: 0.05),
      scheme.surface,
    ),
    textTheme: text.copyWith(
      headlineLarge: text.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
      headlineMedium: text.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
      ),
      headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      titleTextStyle: text.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        color: scheme.onSurface,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 56),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: scheme.outlineVariant, width: 2),
      ),
    ),
    sliderTheme: base.sliderTheme.copyWith(trackHeight: 10),
  );
}
