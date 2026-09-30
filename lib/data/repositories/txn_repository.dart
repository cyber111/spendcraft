import 'package:uuid/uuid.dart';

import '../../core/constants/default_categories.dart';
import '../../services/supabase_service.dart';
import '../../services/sync_service.dart';
import '../local/hive_service.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../models/txn.dart';

/// Single entry point for all data operations.
///
/// The UI never checks auth state. It calls e.g. [addTxn] and the repository
/// decides:
///   - Guest      → write to Hive only
///   - Logged in  → write to Hive immediately, then queue a Supabase sync
class TxnRepository {
  final _uuid = const Uuid();
  final _sync = SyncService.instance;

  bool get _shouldSync => SupabaseService.isLoggedIn;

  // ---- Transactions -----------------------------------------------------

  List<Txn> allTxns() {
    final list = HiveService.txns.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Txn? getTxn(String id) => HiveService.txns.get(id);

  List<Txn> txnsForMonth(DateTime month) {
    return allTxns()
        .where((t) => t.date.year == month.year && t.date.month == month.month)
        .toList();
  }

  Future<Txn> addTxn({
    required double amount,
    required String type,
    required String categoryId,
    String? note,
    required DateTime date,
  }) async {
    final txn = Txn(
      id: _uuid.v4(),
      amount: amount,
      type: type,
      categoryId: categoryId,
      note: (note == null || note.trim().isEmpty) ? null : note.trim(),
      date: date,
      updatedAt: DateTime.now(),
      synced: false,
    );
    await HiveService.txns.put(txn.id, txn);
    if (_shouldSync) _sync.flush();
    return txn;
  }

  Future<void> updateTxn(Txn txn) async {
    txn.updatedAt = DateTime.now();
    txn.synced = false;
    if (txn.note != null && txn.note!.trim().isEmpty) txn.note = null;
    await HiveService.txns.put(txn.id, txn);
    if (_shouldSync) _sync.flush();
  }

  Future<void> deleteTxn(String id) async {
    await HiveService.txns.delete(id);
    if (_shouldSync) await _sync.queueTxnDelete(id);
  }

  // ---- Categories -------------------------------------------------------

  /// Defaults in their seeded order (Food, Transport, … / Salary, …), then
  /// custom categories alphabetically.
  List<Category> allCategories() {
    final list = HiveService.categories.values.toList();
    list.sort((a, b) {
      if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
      if (a.isDefault) return _seedOrder(a.id).compareTo(_seedOrder(b.id));
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
  }

  static final Map<String, int> _seedIndex = {
    for (var i = 0; i < DefaultCategories.expense.length; i++)
      DefaultCategories.expense[i]['id'] as String: i,
    for (var i = 0; i < DefaultCategories.income.length; i++)
      DefaultCategories.income[i]['id'] as String: i,
  };

  static int _seedOrder(String id) => _seedIndex[id] ?? 999;

  List<Category> categoriesOfType(String type) =>
      allCategories().where((c) => c.type == type).toList();

  Category? getCategory(String id) => HiveService.categories.get(id);

  Future<Category> addCategory({
    required String name,
    required String icon,
    required int colorIndex,
    required String type,
  }) async {
    final cat = Category(
      id: 'c_${_uuid.v4().substring(0, 8)}',
      name: name.trim(),
      icon: icon,
      colorIndex: colorIndex,
      type: type,
      isDefault: false,
    );
    await HiveService.categories.put(cat.id, cat);
    if (_shouldSync) _sync.flush();
    return cat;
  }

  Future<void> updateCategory(Category cat) async {
    await HiveService.categories.put(cat.id, cat);
    if (_shouldSync) _sync.flush();
  }

  /// Deleting a category reassigns its transactions to the 'Other' bucket.
  Future<void> deleteCategory(String id) async {
    final cat = getCategory(id);
    if (cat == null || cat.isDefault) return;
    final fallback = cat.isExpense ? 'other_exp' : 'other_inc';
    for (final t in HiveService.txns.values.where((t) => t.categoryId == id)) {
      t.categoryId = fallback;
      t.updatedAt = DateTime.now();
      t.synced = false;
      await t.save();
    }
    await HiveService.categories.delete(id);
    if (_shouldSync) await _sync.queueCatDelete(id);
  }

  // ---- Budgets ----------------------------------------------------------

  static String monthKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  List<Budget> budgetsForMonth(DateTime month) {
    final key = monthKey(month);
    return HiveService.budgets.values.where((b) => b.month == key).toList();
  }

  Budget? overallBudget(DateTime month) {
    final key = monthKey(month);
    for (final b in HiveService.budgets.values) {
      if (b.month == key && b.categoryId == null) return b;
    }
    return null;
  }

  Future<Budget> setBudget({
    required DateTime month,
    String? categoryId,
    required double limit,
  }) async {
    final key = monthKey(month);
    Budget? existing;
    for (final b in HiveService.budgets.values) {
      if (b.month == key && b.categoryId == categoryId) {
        existing = b;
        break;
      }
    }
    if (existing != null) {
      existing.limitAmount = limit;
      await existing.save();
      if (_shouldSync) _sync.flush();
      return existing;
    }
    final budget = Budget(
      id: _uuid.v4(),
      month: key,
      categoryId: categoryId,
      limitAmount: limit,
    );
    await HiveService.budgets.put(budget.id, budget);
    if (_shouldSync) _sync.flush();
    return budget;
  }

  Future<void> deleteBudget(String id) async {
    await HiveService.budgets.delete(id);
    if (_shouldSync) await _sync.queueBudgetDelete(id);
  }

  // ---- Bulk -------------------------------------------------------------

  Future<void> clearAll() => HiveService.clearAllData();
}
