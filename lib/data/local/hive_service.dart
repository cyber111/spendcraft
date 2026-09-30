import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants/default_categories.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../models/txn.dart';

class HiveService {
  static const txnsBox = 'txns';
  static const categoriesBox = 'categories';
  static const budgetsBox = 'budgets';
  static const settingsBox = 'settings';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(TxnAdapter());
    Hive.registerAdapter(CategoryAdapter());
    Hive.registerAdapter(BudgetAdapter());

    await Hive.openBox<Txn>(txnsBox);
    await Hive.openBox<Category>(categoriesBox);
    await Hive.openBox<Budget>(budgetsBox);
    await Hive.openBox(settingsBox);

    await _seedCategories();
  }

  static Box<Txn> get txns => Hive.box<Txn>(txnsBox);
  static Box<Category> get categories => Hive.box<Category>(categoriesBox);
  static Box<Budget> get budgets => Hive.box<Budget>(budgetsBox);
  static Box get settings => Hive.box(settingsBox);

  /// Pre-seed default categories on first launch (keyed by category id).
  static Future<void> _seedCategories() async {
    final box = categories;
    if (box.isNotEmpty) return;
    for (final c in DefaultCategories.expense) {
      await box.put(
        c['id'] as String,
        Category(
          id: c['id'] as String,
          name: c['name'] as String,
          icon: c['icon'] as String,
          colorIndex: c['color'] as int,
          type: 'expense',
          isDefault: true,
        ),
      );
    }
    for (final c in DefaultCategories.income) {
      await box.put(
        c['id'] as String,
        Category(
          id: c['id'] as String,
          name: c['name'] as String,
          icon: c['icon'] as String,
          colorIndex: c['color'] as int,
          type: 'income',
          isDefault: true,
        ),
      );
    }
  }

  // Settings helpers.
  static bool get onboarded => settings.get('onboarded', defaultValue: false) as bool;
  static set onboarded(bool v) => settings.put('onboarded', v);

  static String get themeMode => settings.get('themeMode', defaultValue: 'system') as String;
  static set themeMode(String v) => settings.put('themeMode', v);

  static String get designSystem =>
      settings.get('designSystem', defaultValue: 'foodDelivery') as String;
  static set designSystem(String v) => settings.put('designSystem', v);

  static String get currencySymbol => settings.get('currency', defaultValue: '₹') as String;
  static set currencySymbol(String v) => settings.put('currency', v);

  static bool get guestBannerDismissed =>
      settings.get('guestBannerDismissed', defaultValue: false) as bool;
  static set guestBannerDismissed(bool v) => settings.put('guestBannerDismissed', v);

  static Future<void> clearAllData() async {
    await txns.clear();
    await budgets.clear();
    // Remove custom categories but keep defaults.
    final customKeys =
        categories.values.where((c) => !c.isDefault).map((c) => c.id).toList();
    for (final k in customKeys) {
      await categories.delete(k);
    }
  }
}
