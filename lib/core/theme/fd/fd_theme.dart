// Vendored from FoodDelivery/packages/fd_ui (FoodDeliveryAppDesignSystem).
// Do not edit here — re-copy from the source repo when the design system changes.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'fd_tokens.g.dart';

/// Type styles in Inter, coloured for the active theme. Read with `context.fdType`.
@immutable
class FdTypography extends ThemeExtension<FdTypography> {
  const FdTypography({
    required this.display,
    required this.h1,
    required this.h2,
    required this.h3,
    required this.body,
    required this.bodyStrong,
    required this.small,
    required this.smallStrong,
    required this.label,
    required this.caption,
    required this.numericLg,
  });

  factory FdTypography.forColors(FdColors c) {
    TextStyle inter(TextStyle s) => GoogleFonts.inter(textStyle: s.copyWith(color: c.textPrimary));
    return FdTypography(
      display: inter(FdText.display),
      h1: inter(FdText.h1),
      h2: inter(FdText.h2),
      h3: inter(FdText.h3),
      body: inter(FdText.body),
      bodyStrong: inter(FdText.bodyStrong),
      small: inter(FdText.small),
      smallStrong: inter(FdText.smallStrong),
      label: inter(FdText.label),
      caption: inter(FdText.caption),
      numericLg: inter(FdText.numericLg),
    );
  }

  final TextStyle display, h1, h2, h3, body, bodyStrong, small, smallStrong, label, caption, numericLg;

  @override
  FdTypography copyWith() => this;

  @override
  FdTypography lerp(ThemeExtension<FdTypography>? other, double t) =>
      t < 0.5 || other is! FdTypography ? this : other;
}

extension FdThemeContext on BuildContext {
  FdColors get fd => Theme.of(this).extension<FdColors>()!;
  FdTypography get fdType => Theme.of(this).extension<FdTypography>()!;
}

/// Tabular figures for prices, times, distances and counts (`.fd-num`).
extension FdNum on TextStyle {
  TextStyle get num => copyWith(fontFeatures: FdText.num);
}

abstract final class FdTheme {
  static ThemeData light() => _build(FdColors.light, Brightness.light);
  static ThemeData dark() => _build(FdColors.dark, Brightness.dark);

  static ThemeData _build(FdColors c, Brightness brightness) {
    final type = FdTypography.forColors(c);
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      secondary: c.primary,
      onSecondary: c.onPrimary,
      error: c.error,
      onError: c.onError,
      surface: c.surface,
      onSurface: c.textPrimary,
      onSurfaceVariant: c.textSecondary,
      outline: c.borderStrong,
      outlineVariant: c.border,
      surfaceContainerLowest: c.background,
      surfaceContainerLow: c.surfaceSubtle,
      surfaceContainer: c.surfaceSubtle,
      surfaceContainerHigh: c.surfacePressed,
      surfaceContainerHighest: c.surfacePressed,
      scrim: c.overlay,
      shadow: const Color(0xFF000000),
      inverseSurface: c.textPrimary,
      onInverseSurface: c.background,
      surfaceTint: const Color(0x00000000),
    );

    const smallRadius = BorderRadius.all(Radius.circular(FdRadius.sm));
    const mediumRadius = BorderRadius.all(Radius.circular(FdRadius.md));
    OutlineInputBorder field(Color color, [double width = FdBorder.hairline]) => OutlineInputBorder(
          borderRadius: smallRadius,
          borderSide: BorderSide(color: color, width: width),
        );
    final isLight = brightness == Brightness.light;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      dividerColor: c.divider,
      splashFactory: NoSplash.splashFactory,
      highlightColor: c.surfacePressed,
      hoverColor: c.surfacePressed,
      focusColor: c.surfacePressed,
      extensions: [c, type],
      textTheme: TextTheme(
        displayLarge: type.display,
        headlineLarge: type.h1,
        headlineMedium: type.h2,
        titleLarge: type.h3,
        titleMedium: type.bodyStrong,
        titleSmall: type.smallStrong,
        bodyLarge: type.body,
        bodyMedium: type.small,
        bodySmall: type.caption.copyWith(color: c.textTertiary),
        labelLarge: type.bodyStrong,
        labelMedium: type.label,
        labelSmall: type.caption,
      ),
      iconTheme: IconThemeData(color: c.textPrimary, size: FdSize.icon),
      dividerTheme: DividerThemeData(color: c.divider, thickness: FdBorder.hairline, space: FdBorder.hairline),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: FdSize.appBar,
        titleTextStyle: type.bodyStrong.copyWith(fontSize: 17, fontWeight: FontWeight.w600),
        shape: Border(bottom: BorderSide(color: c.border)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: FdSize.tabBar,
        backgroundColor: c.background,
        indicatorColor: const Color(0x00000000),
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((s) => type.caption.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: s.contains(WidgetState.selected) ? c.textPrimary : c.textTertiary,
            )),
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
              size: 24,
              color: s.contains(WidgetState.selected) ? c.textPrimary : c.textTertiary,
            )),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: c.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: FdSpace.s3, vertical: 10),
        hintStyle: type.body.copyWith(color: c.textTertiary),
        labelStyle: type.label,
        floatingLabelBehavior: FloatingLabelBehavior.never,
        helperStyle: type.caption.copyWith(color: c.textTertiary),
        errorStyle: type.caption.copyWith(color: c.error),
        prefixIconColor: c.textSecondary,
        suffixIconColor: c.textSecondary,
        border: field(c.borderStrong),
        enabledBorder: field(c.borderStrong),
        hoverColor: const Color(0x00000000),
        focusedBorder: field(c.focusRing, FdBorder.focus),
        errorBorder: field(c.error),
        focusedErrorBorder: field(c.error, FdBorder.focus),
        disabledBorder: field(c.disabled),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.disabled)) return c.onDisabled;
          return s.contains(WidgetState.selected) ? c.onPrimary : c.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.disabled)) return c.disabled;
          return s.contains(WidgetState.selected) ? c.primary : c.background;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.disabled)) return c.disabled;
          return s.contains(WidgetState.selected) ? c.primary : c.borderStrong;
        }),
        trackOutlineWidth: const WidgetStatePropertyAll(FdBorder.hairline),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: const RoundedRectangleBorder(borderRadius: smallRadius),
        side: BorderSide(color: c.borderStrong),
        fillColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? c.primary : const Color(0x00000000)),
        checkColor: WidgetStatePropertyAll(c.onPrimary),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? c.primary : c.borderStrong),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.background,
        selectedColor: c.primary,
        disabledColor: c.background,
        side: BorderSide(color: c.borderStrong),
        shape: const RoundedRectangleBorder(borderRadius: smallRadius),
        labelStyle: type.label,
        secondaryLabelStyle: type.label.copyWith(color: c.onPrimary),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: FdSpace.s1),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surfaceRaised,
        modalBackgroundColor: c.surfaceRaised,
        surfaceTintColor: const Color(0x00000000),
        elevation: isLight ? 8 : 0,
        modalBarrierColor: c.overlay,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(FdRadius.md)),
          side: BorderSide(color: c.border),
        ),
        showDragHandle: true,
        dragHandleColor: c.border,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surfaceRaised,
        surfaceTintColor: const Color(0x00000000),
        elevation: isLight ? 8 : 0,
        barrierColor: c.overlay,
        shape: RoundedRectangleBorder(borderRadius: mediumRadius, side: BorderSide(color: c.border)),
        titleTextStyle: type.h3,
        contentTextStyle: type.body.copyWith(color: c.textSecondary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.textPrimary,
        contentTextStyle: type.small.copyWith(color: c.background),
        actionTextColor: c.background,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: mediumRadius),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.textPrimary,
        linearTrackColor: c.surfaceSubtle,
        circularTrackColor: const Color(0x00000000),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        surfaceTintColor: const Color(0x00000000),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: mediumRadius, side: BorderSide(color: c.border)),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: FdSpace.s4),
        titleTextStyle: type.bodyStrong,
        subtitleTextStyle: type.small.copyWith(color: c.textSecondary),
        iconColor: c.textPrimary,
      ),
    );
  }
}
