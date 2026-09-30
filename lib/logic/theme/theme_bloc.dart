import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_skin.dart';
import '../../core/utils/money_format.dart';
import '../../data/local/hive_service.dart';

class ThemeState {
  final ThemeMode mode;
  final String currency;
  final DesignSystem design;
  const ThemeState({required this.mode, required this.currency, required this.design});

  ThemeState copyWith({ThemeMode? mode, String? currency, DesignSystem? design}) => ThemeState(
        mode: mode ?? this.mode,
        currency: currency ?? this.currency,
        design: design ?? this.design,
      );
}

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit()
      : super(ThemeState(
          mode: _parse(HiveService.themeMode),
          currency: HiveService.currencySymbol,
          design: DesignSystem.values.asNameMap()[HiveService.designSystem] ??
              DesignSystem.foodDelivery,
        )) {
    MoneyFormat.symbol = state.currency;
  }

  static ThemeMode _parse(String s) {
    switch (s) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _toString(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  void setMode(ThemeMode mode) {
    HiveService.themeMode = _toString(mode);
    emit(state.copyWith(mode: mode));
  }

  void setCurrency(String symbol) {
    HiveService.currencySymbol = symbol;
    MoneyFormat.symbol = symbol;
    emit(state.copyWith(currency: symbol));
  }

  void setDesign(DesignSystem design) {
    HiveService.designSystem = design.name;
    emit(state.copyWith(design: design));
  }
}
