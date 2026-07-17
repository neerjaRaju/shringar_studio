import 'package:flutter/material.dart';

/// Material 3 theme with a Shringar-inspired maroon/gold seed, plus support
/// for Material You dynamic colors (wired in [app.dart]).
abstract final class AppTheme {
  static const _seed = Color(0xFF8E1B3A); // deep rani maroon
  static const _gold = Color(0xFFC9A227);

  static ThemeData light([ColorScheme? dynamicScheme]) => _build(
        dynamicScheme ??
            ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.light),
      );

  static ThemeData dark([ColorScheme? dynamicScheme]) => _build(
        dynamicScheme ??
            ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark),
      );

  static ThemeData _build(ColorScheme scheme) {
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        clipBehavior: Clip.antiAlias,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 2,
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.primaryContainer,
      ),
      extensions: const [_ShringarColors(gold: _gold)],
    );
  }
}

/// Accent gold available via `Theme.of(context).extension<ShringarColors>()`.
class _ShringarColors extends ThemeExtension<_ShringarColors> {
  const _ShringarColors({required this.gold});
  final Color gold;

  @override
  ThemeExtension<_ShringarColors> copyWith({Color? gold}) =>
      _ShringarColors(gold: gold ?? this.gold);

  @override
  ThemeExtension<_ShringarColors> lerp(
          covariant ThemeExtension<_ShringarColors>? other, double t) =>
      this;
}

/// Parse a `#rrggbb` string to a [Color], tolerant of bad input.
Color hexToColor(String hex, {Color fallback = const Color(0xFF888888)}) {
  final cleaned = hex.replaceAll('#', '').trim();
  if (cleaned.length != 6) return fallback;
  final value = int.tryParse('FF$cleaned', radix: 16);
  return value == null ? fallback : Color(value);
}
