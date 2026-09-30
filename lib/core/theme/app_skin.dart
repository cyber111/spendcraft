import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_theme.dart';
import 'fd/fd_theme.dart';
import 'fd/fd_tokens.g.dart';

/// Which design system the UI is drawn with. Switchable in Settings.
enum DesignSystem {
  spendcraft('SpendCraft'),
  foodDelivery('FoodDelivery');

  const DesignSystem(this.label);
  final String label;
}

/// Every visual role SpendCraft's widgets need, resolved for one design
/// system + brightness. Widgets read `context.skin` and never reach for
/// [AppColors] or Fd tokens directly, so swapping systems is one theme change.
@immutable
class AppSkin extends ThemeExtension<AppSkin> {
  const AppSkin({
    required this.system,
    required this.primary,
    required this.onPrimary,
    required this.primarySoft,
    required this.income,
    required this.expense,
    required this.warning,
    required this.card,
    required this.cardBorder,
    required this.controlBorder,
    required this.subtle,
    required this.text,
    required this.muted,
    required this.heroGradient,
    required this.heroBorder,
    required this.heroFg,
    required this.heroFgMuted,
    required this.heroChip,
    required this.radiusCard,
    required this.radiusControl,
    required this.shadows,
    required this.catColors,
  });

  final DesignSystem system;

  /// CTA fills, selected states, links and accent icons.
  final Color primary;
  final Color onPrimary;

  /// Quiet fill behind a selected/active item (nav indicator, soft icon wells).
  final Color primarySoft;

  final Color income;
  final Color expense;

  /// Budget near-limit (>80%).
  final Color warning;

  /// Card / tile / keypad ground and its outline (transparent = no outline).
  final Color card;
  final Color cardBorder;

  /// 1px outline on interactive controls (keys, chips); transparent = none.
  final Color controlBorder;

  /// Neutral quiet fill: placeholders, progress tracks, inactive chips.
  final Color subtle;

  final Color text;
  final Color muted;

  /// Balance card. A gradient in SpendCraft; FoodDelivery uses a flat bordered
  /// surface (null gradient) because it separates by hairline, never by fill.
  final Gradient? heroGradient;
  final Color heroBorder;
  final Color heroFg;
  final Color heroFgMuted;
  final Color heroChip;

  final double radiusCard;
  final double radiusControl;
  final bool shadows;

  /// Chart series colours, indexed by a category's colorIndex.
  final List<Color> catColors;

  bool get isFoodDelivery => system == DesignSystem.foodDelivery;

  Color cat(int index) => catColors[index % catColors.length];

  /// Chart series. FoodDelivery forbids coloured fills, so its bars are ink
  /// (income) vs mid-grey (expense); SpendCraft keeps green vs red.
  Color get seriesIncome => isFoodDelivery ? primary : income;
  Color get seriesExpense => isFoodDelivery ? catColors[3] : expense;

  /// Chart gridlines / hairlines.
  Color get hairline => isFoodDelivery ? cardBorder : subtle;

  /// Budget bar: normal → primary, >80% → warning, over → expense.
  Color budgetColor(double ratio) {
    if (ratio >= 1.0) return expense;
    if (ratio >= 0.8) return warning;
    return primary;
  }

  /// Soft well behind an emoji / icon that belongs to [color].
  /// FoodDelivery never tints by hue — it uses the one neutral quiet fill.
  Color tint(Color color) => isFoodDelivery ? subtle : color.withValues(alpha: 0.14);

  /// Colour for "this item is selected" when the item has its own hue.
  Color emphasis(Color color) => isFoodDelivery ? primary : color;

  /// Standard card: fill + optional hairline + radius.
  BoxDecoration cardDecoration({Color? color}) => BoxDecoration(
        color: color ?? card,
        borderRadius: BorderRadius.circular(radiusCard),
        border: cardBorder.a == 0 ? null : Border.all(color: cardBorder),
      );

  BorderRadius get cardRadius => BorderRadius.circular(radiusCard);
  BorderRadius get controlRadius => BorderRadius.circular(radiusControl);

  /// Big money figures.
  TextStyle amount({double size = 40, Color? color, FontWeight? weight}) {
    if (isFoodDelivery) {
      return GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight ?? FontWeight.w600,
        letterSpacing: -0.02 * size,
        color: color ?? text,
        fontFeatures: FdText.num,
      );
    }
    return GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: weight ?? FontWeight.w700,
      letterSpacing: -0.5,
      color: color ?? text,
    );
  }

  // ---- The two systems ----------------------------------------------------

  static AppSkin spendcraft(Brightness b) {
    final dark = b == Brightness.dark;
    return AppSkin(
      system: DesignSystem.spendcraft,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primarySoft: AppColors.primary.withValues(alpha: 0.15),
      income: AppColors.income,
      expense: AppColors.expense,
      warning: AppColors.accent,
      card: dark ? AppColors.cardDark : AppColors.cardLight,
      cardBorder: Colors.transparent,
      controlBorder: Colors.transparent,
      subtle: dark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
      text: dark ? AppColors.textDark : AppColors.textLight,
      muted: dark ? AppColors.textDarkMuted : AppColors.textLightMuted,
      heroGradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primary, AppColors.income],
      ),
      heroBorder: Colors.transparent,
      heroFg: Colors.white,
      heroFgMuted: Colors.white70,
      heroChip: Colors.white.withValues(alpha: 0.16),
      radiusCard: 18,
      radiusControl: 14,
      shadows: true,
      catColors: AppColors.catColors,
    );
  }

  static AppSkin foodDelivery(Brightness b) {
    final c = b == Brightness.dark ? FdColors.dark : FdColors.light;
    return AppSkin(
      system: DesignSystem.foodDelivery,
      primary: c.primary,
      onPrimary: c.onPrimary,
      primarySoft: c.surfaceSubtle,
      income: c.success,
      expense: c.error,
      warning: c.warning,
      card: c.surface,
      cardBorder: c.border,
      controlBorder: c.borderStrong,
      subtle: c.surfaceSubtle,
      text: c.textPrimary,
      muted: c.textSecondary,
      heroGradient: null,
      heroBorder: c.border,
      heroFg: c.textPrimary,
      heroFgMuted: c.textSecondary,
      heroChip: c.surfaceSubtle,
      radiusCard: FdRadius.md,
      radiusControl: FdRadius.sm,
      shadows: false,
      // Monochrome system → charts use the grey ramp, darkest first.
      catColors: [c.grey1000, c.grey700, c.grey500, c.grey400, c.grey200, c.grey900],
    );
  }

  static ThemeData theme(DesignSystem system, Brightness b) {
    final light = b == Brightness.light;
    switch (system) {
      case DesignSystem.spendcraft:
        final base = light ? AppTheme.light : AppTheme.dark;
        return base.copyWith(extensions: [spendcraft(b)]);
      case DesignSystem.foodDelivery:
        final base = light ? FdTheme.light() : FdTheme.dark();
        final skin = foodDelivery(b);
        return base.copyWith(
          extensions: [...base.extensions.values, skin],
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: skin.primary,
            foregroundColor: skin.onPrimary,
            elevation: 0,
            highlightElevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FdRadius.md)),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: skin.primary,
              foregroundColor: skin.onPrimary,
              minimumSize: const Size(0, FdSize.controlMd),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FdRadius.sm)),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: skin.text,
              side: BorderSide(color: skin.controlBorder),
              minimumSize: const Size(0, FdSize.controlMd),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FdRadius.sm)),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: skin.text),
          ),
        );
    }
  }

  // ---- ThemeExtension plumbing ---------------------------------------------

  @override
  AppSkin copyWith() => this;

  /// Snap instead of blending — interpolating teal→ink mid-switch looks muddy.
  @override
  AppSkin lerp(ThemeExtension<AppSkin>? other, double t) =>
      t < 0.5 || other is! AppSkin ? this : other;
}

extension AppSkinContext on BuildContext {
  AppSkin get skin => Theme.of(this).extension<AppSkin>()!;
}
