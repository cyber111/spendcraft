import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../data/local/hive_service.dart';
import '../data/models/budget.dart';
import '../data/models/category.dart';
import '../data/models/txn.dart';
import 'supabase_service.dart';

/// V1 sync: last-write-wins by `updatedAt`.
///
/// - Writes go to Hive first (immediate), then are pushed in the background.
/// - Unsynced rows (`synced == false`) are retried whenever we come online.
/// - Deletes while offline are queued in the settings box and flushed later.
class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  final _connectivity = Connectivity();
  StreamSubscription? _connSub;
  bool _online = true;
  bool _syncing = false;

  final _statusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get status => _statusController.stream;

  static const _pendingDeletesKey = 'pendingTxnDeletes';
  static const _pendingCatDeletesKey = 'pendingCatDeletes';
  static const _pendingBudgetDeletesKey = 'pendingBudgetDeletes';

  bool get isOnline => _online;

  Future<void> start() async {
    final result = await _connectivity.checkConnectivity();
    _online = _hasConnection(result);
    _connSub ??= _connectivity.onConnectivityChanged.listen((result) {
      final wasOnline = _online;
      _online = _hasConnection(result);
      if (!wasOnline && _online && SupabaseService.isLoggedIn) {
        flush();
      }
    });
  }

  bool _hasConnection(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  void dispose() {
    _connSub?.cancel();
    _connSub = null;
  }

  String? get _userId => SupabaseService.currentUser?.id;

  // ---- Pull -------------------------------------------------------------

  /// Pull all remote rows and merge into Hive. Remote wins on conflict by
  /// `updated_at`. Local unsynced rows that are newer stay and get pushed.
  Future<void> pullAll() async {
    final uid = _userId;
    if (uid == null || !_online) return;
    _emit(SyncStatus.syncing);
    try {
      final remoteTxns = await SupabaseService.fetchTxns(uid);
      final box = HiveService.txns;
      for (final row in remoteTxns) {
        final remote = Txn.fromSupabaseJson(row);
        final local = box.get(remote.id);
        if (local == null) {
          await box.put(remote.id, remote);
        } else if (!local.updatedAt.isAfter(remote.updatedAt)) {
          // Remote is same or newer → remote wins.
          await box.put(remote.id, remote);
        }
        // Else local is newer and unsynced → keep it, push later.
      }

      final remoteCats = await SupabaseService.fetchCategories(uid);
      final catBox = HiveService.categories;
      for (final row in remoteCats) {
        final remote = Category.fromSupabaseJson(row);
        final local = catBox.get(remote.id);
        if (local == null || !local.isDefault) {
          await catBox.put(remote.id, remote);
        }
      }

      final remoteBudgets = await SupabaseService.fetchBudgets(uid);
      final budBox = HiveService.budgets;
      for (final row in remoteBudgets) {
        final remote = Budget.fromSupabaseJson(row);
        await budBox.put(remote.id, remote);
      }
      _emit(SyncStatus.idle);
    } catch (e) {
      _emit(SyncStatus.error);
    }
  }

  // ---- Push -------------------------------------------------------------

  /// Push every unsynced local txn plus queued deletes.
  Future<void> flush() async {
    final uid = _userId;
    if (uid == null || !_online || _syncing) return;
    _syncing = true;
    _emit(SyncStatus.syncing);
    try {
      // Txns
      final box = HiveService.txns;
      final unsynced = box.values.where((t) => !t.synced).toList();
      if (unsynced.isNotEmpty) {
        await SupabaseService.upsertTxns(
          unsynced.map((t) => t.toSupabaseJson(uid)).toList(),
        );
        for (final t in unsynced) {
          t.synced = true;
          await t.save();
        }
      }

      // Queued txn deletes
      final pending = _pendingList(_pendingDeletesKey);
      for (final id in List<String>.from(pending)) {
        await SupabaseService.deleteTxn(id);
        pending.remove(id);
      }
      await HiveService.settings.put(_pendingDeletesKey, pending);

      // Categories: push all custom ones (cheap, few rows)
      final customCats = HiveService.categories.values.where((c) => !c.isDefault).toList();
      await SupabaseService.upsertCategories(
        customCats.map((c) => c.toSupabaseJson(uid)).toList(),
      );
      final pendingCats = _pendingList(_pendingCatDeletesKey);
      for (final id in List<String>.from(pendingCats)) {
        await SupabaseService.deleteCategory(id, uid);
        pendingCats.remove(id);
      }
      await HiveService.settings.put(_pendingCatDeletesKey, pendingCats);

      // Budgets: push all (few rows per user)
      final budgets = HiveService.budgets.values.toList();
      await SupabaseService.upsertBudgets(
        budgets.map((b) => b.toSupabaseJson(uid)).toList(),
      );
      final pendingBudgets = _pendingList(_pendingBudgetDeletesKey);
      for (final id in List<String>.from(pendingBudgets)) {
        await SupabaseService.deleteBudget(id);
        pendingBudgets.remove(id);
      }
      await HiveService.settings.put(_pendingBudgetDeletesKey, pendingBudgets);

      _emit(SyncStatus.idle);
    } catch (e) {
      _emit(SyncStatus.error);
    } finally {
      _syncing = false;
    }
  }

  /// Upload everything local (used on first login: "Upload your existing data?").
  Future<void> uploadAllLocal() async {
    for (final t in HiveService.txns.values) {
      t.synced = false;
      await t.save();
    }
    await flush();
  }

  /// Full reconcile: pull then push.
  Future<void> reconcile() async {
    await pullAll();
    await flush();
  }

  // ---- Queued deletes ---------------------------------------------------

  /// Forget every queued remote delete (used when the account is deleted).
  Future<void> clearQueues() async {
    for (final k in [_pendingDeletesKey, _pendingCatDeletesKey, _pendingBudgetDeletesKey]) {
      await HiveService.settings.delete(k);
    }
  }

  Future<void> queueTxnDelete(String id) => _queue(_pendingDeletesKey, id);
  Future<void> queueCatDelete(String id) => _queue(_pendingCatDeletesKey, id);
  Future<void> queueBudgetDelete(String id) => _queue(_pendingBudgetDeletesKey, id);

  Future<void> _queue(String key, String id) async {
    final list = _pendingList(key);
    if (!list.contains(id)) list.add(id);
    await HiveService.settings.put(key, list);
    if (_online) flush();
  }

  List<String> _pendingList(String key) {
    final raw = HiveService.settings.get(key);
    if (raw is List) return List<String>.from(raw);
    return <String>[];
  }

  void _emit(SyncStatus s) {
    if (!_statusController.isClosed) _statusController.add(s);
  }
}

enum SyncStatus { idle, syncing, error }
