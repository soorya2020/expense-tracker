import 'package:flutter/material.dart';

import '../shared/motion.dart';

const _font = 'InterTight';

/// The Big Number palette. Ink on white, one colour per kind of money.
@immutable
class Palette extends ThemeExtension<Palette> {
  const Palette({
    required this.bg,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.line,
    required this.salary,
    required this.salarySoft,
    required this.extra,
    required this.extraSoft,
    required this.help,
    required this.helpSoft,
    required this.over,
    required this.overSoft,
    required this.onInk,
  });

  final Color bg, surface, ink, muted, line;
  final Color salary, salarySoft, extra, extraSoft, help, helpSoft, over, overSoft;
  final Color onInk;

  static const light = Palette(
    bg: Color(0xFFFFFFFF),
    surface: Color(0xFFF5F6F8),
    ink: Color(0xFF0F1115),
    muted: Color(0xFF7B8090),
    line: Color(0xFFECEEF2),
    salary: Color(0xFF2B4CFF),
    salarySoft: Color(0xFFE8ECFF),
    extra: Color(0xFFF29F05),
    extraSoft: Color(0xFFFFF3DC),
    help: Color(0xFF12A594),
    helpSoft: Color(0xFFDDF5F1),
    over: Color(0xFFE5484D),
    overSoft: Color(0xFFFDE8E9),
    onInk: Color(0xFFFFFFFF),
  );

  static const dark = Palette(
    bg: Color(0xFF0A0E17),
    surface: Color(0xFF141A27),
    ink: Color(0xFFEEF2FA),
    muted: Color(0xFF8A93A8),
    line: Color(0xFF252D3F),
    salary: Color(0xFF6E86FF),
    salarySoft: Color(0xFF1C2447),
    extra: Color(0xFFFFB547),
    extraSoft: Color(0xFF33280F),
    help: Color(0xFF34D3B0),
    helpSoft: Color(0xFF0F2E2A),
    over: Color(0xFFFF6B81),
    overSoft: Color(0xFF3A1A22),
    onInk: Color(0xFF0A0E17),
  );

  /// Colour for an income kind.
  Color forIncome(String? kind) => switch (kind) {
        'salary' => salary,
        'extra' => extra,
        'help' => help,
        'borrowed' => muted,
        _ => ink,
      };

  @override
  Palette copyWith() => this;

  @override
  Palette lerp(ThemeExtension<Palette>? other, double t) =>
      t < .5 ? this : (other as Palette? ?? this);
}

extension PaletteX on BuildContext {
  Palette get p => Theme.of(this).extension<Palette>()!;
}

/// Type scale from the design: balance 52/900, story 34/900, title 26/900,
/// sentence 17/600, body 13/500, label 11/600.
abstract final class T {
  static const huge = TextStyle(fontFamily: _font, fontSize: 52, fontWeight: FontWeight.w900, letterSpacing: -2.3, height: 1, fontFeatures: [FontFeature.tabularFigures()]);
  static const story = TextStyle(fontFamily: _font, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -1.4, height: 1.05);
  static const title = TextStyle(fontFamily: _font, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.9, height: 1.05);
  static const sentence = TextStyle(fontFamily: _font, fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.2, height: 1.3);
  static const body = TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w500, fontFeatures: [FontFeature.tabularFigures()]);
  static const bodyBold = TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w800, fontFeatures: [FontFeature.tabularFigures()]);
  static const label = TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.w600);
  static const caps = TextStyle(fontFamily: _font, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.9);
}

ThemeData buildTheme(Brightness b) {
  final p = b == Brightness.dark ? Palette.dark : Palette.light;
  final scheme = ColorScheme.fromSeed(
    seedColor: p.salary,
    brightness: b,
    surface: p.bg,
    primary: p.ink,
    onPrimary: p.onInk,
    secondary: p.salary,
    error: p.over,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: b,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.bg,
    fontFamily: _font,
    extensions: [p],
    splashFactory: InkSparkle.splashFactory,
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: SlideBackTransitionsBuilder(),
      TargetPlatform.iOS: SlideBackTransitionsBuilder(),
    }),
    appBarTheme: AppBarTheme(backgroundColor: p.bg, foregroundColor: p.ink, elevation: 0, scrolledUnderElevation: 0),
    dividerTheme: DividerThemeData(color: p.line, thickness: 1, space: 1),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.ink,
      contentTextStyle: T.body.copyWith(color: p.bg),
      behavior: SnackBarBehavior.floating,
      shape: const StadiumBorder(),
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.ink : p.line),
      thumbColor: WidgetStatePropertyAll(p.bg),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      hintStyle: T.body.copyWith(color: p.muted),
    ),
    datePickerTheme: DatePickerThemeData(backgroundColor: p.bg, headerBackgroundColor: p.ink, headerForegroundColor: p.bg),
  );
}
