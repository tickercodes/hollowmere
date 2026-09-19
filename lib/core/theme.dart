import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Visual identity from the story bible §14: near-black glass, teal accent,
/// amber alerts, magenta/cyan glitch splits.
class HmColors {
  const HmColors._();
  static const bg = Color(0xFF0A0C0E);
  static const surface = Color(0xFF121619);
  static const surfaceRaised = Color(0xFF1A2024);
  static const hairline = Color(0xFF2A3338);
  static const teal = Color(0xFF4FD1C5);
  static const tealDim = Color(0xFF1E5E5A);
  static const amber = Color(0xFFF2A93B);
  static const danger = Color(0xFFE05555);
  static const ok = Color(0xFF5CC97A);
  static const text = Color(0xFFE6EAEC);
  static const textDim = Color(0xFF8A969C);
  static const bubbleIn = Color(0xFF232A2E);
  static const bubbleOut = Color(0xFF12403D);
  static const glitchMagenta = Color(0xFFFF2BD6);
  static const glitchCyan = Color(0xFF2BF0FF);
  static const paper = Color(0xFFE9E2D3);
  static const paperInk = Color(0xFF2B2A28);
}

ThemeData buildTheme() {
  const scheme = ColorScheme.dark(
    primary: HmColors.teal,
    onPrimary: HmColors.bg,
    secondary: HmColors.amber,
    surface: HmColors.surface,
    onSurface: HmColors.text,
    error: HmColors.danger,
    surfaceTint: Colors.transparent,
    // AppBar uses these when content scrolls underneath. Keep them on the
    // same fill as the scaffold so the bar never shifts colour.
    surfaceContainer: HmColors.bg,
    surfaceContainerHigh: HmColors.bg,
    surfaceContainerHighest: HmColors.bg,
    surfaceContainerLowest: HmColors.bg,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    applyElevationOverlayColor: false,
  );
  return base.copyWith(
    scaffoldBackgroundColor: HmColors.bg,
    textTheme: base.textTheme.apply(
      bodyColor: HmColors.text,
      displayColor: HmColors.text,
      decoration: TextDecoration.none,
    ),
    primaryTextTheme: base.primaryTextTheme.apply(
      bodyColor: HmColors.text,
      displayColor: HmColors.text,
      decoration: TextDecoration.none,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: HmColors.surfaceRaised,
      hintStyle: const TextStyle(color: HmColors.textDim),
      counterStyle: const TextStyle(color: HmColors.textDim),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: HmColors.hairline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: HmColors.hairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: HmColors.teal),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: HmColors.bg,
      foregroundColor: HmColors.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      titleTextStyle: TextStyle(
        color: HmColors.text,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        decoration: TextDecoration.none,
      ),
      toolbarTextStyle: TextStyle(
        color: HmColors.text,
        decoration: TextDecoration.none,
      ),
    ),
    dividerColor: HmColors.hairline,
    splashFactory: InkSparkle.splashFactory,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: HmColors.teal,
        foregroundColor: HmColors.bg,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: HmColors.text,
        side: const BorderSide(color: HmColors.tealDim),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: HmColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
  );
}

/// Monospace style used for transcripts, logs and codes.
const monoStyle = TextStyle(
  fontFamily: 'Menlo',
  fontFamilyFallback: ['Courier New', 'monospace'],
  fontSize: 13,
  height: 1.45,
  color: HmColors.text,
  decoration: TextDecoration.none,
);

/// Serif display style for title cards and episode names.
const displayStyle = TextStyle(
  fontFamily: 'Georgia',
  fontFamilyFallback: ['Times New Roman', 'serif'],
  fontWeight: FontWeight.w600,
  letterSpacing: 1.5,
  color: HmColors.text,
  decoration: TextDecoration.none,
);
