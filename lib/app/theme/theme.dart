import 'package:flutter/material.dart';

import 'colors.dart';

/// Uygulama teması — saha koşullarına göre ayarlandı:
/// güneş altında okunabilir yüksek kontrast, eldivenle kullanılabilir
/// büyük dokunma hedefleri (min 48dp), açık zemin üzerine koyu metin.
ThemeData buildBaibarsTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: BaibarsColors.blue,
    primary: BaibarsColors.blue,
    secondary: BaibarsColors.deepGreen,
    tertiary: BaibarsColors.lime,
    brightness: Brightness.light,
  );

  const minTouchTarget = Size(48, 56);

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: Colors.white,
    visualDensity: VisualDensity.standard,
    textTheme: const TextTheme(
      // Datasheet hiyerarşisi: güçlü, kalın başlıklar.
      headlineLarge: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
      headlineMedium: TextStyle(fontWeight: FontWeight.w700),
      titleLarge: TextStyle(fontWeight: FontWeight.w700),
      // Teknik değerler (seri no, sayaçlar) tabular rakamla hizalanır.
      bodyLarge: TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: minTouchTarget,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(minimumSize: minTouchTarget),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: minTouchTarget),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF4F6F8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: BaibarsColors.blue, width: 2),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: BaibarsColors.deepGreen,
      elevation: 0,
      centerTitle: false,
    ),
  );
}
