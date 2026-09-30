import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/budget.dart';
import '../../data/repositories/txn_repository.dart';

// ---- Events -------------------------------------------------------------

abstract class BudgetEvent extends Equatable {
  const BudgetEvent();
  @override
  List<Object?> get props => [];
}

class BudgetLoaded extends BudgetEvent {
  final DateTime month;
  const BudgetLoaded(this.month);
  @override
  List<Object?> get props => [month];
}

class BudgetSet extends BudgetEvent {
  final DateTime month;
  final String? categoryId;
  final double limit;
  const BudgetSet({required this.month, this.categoryId, required this.limit});
  @override
  List<Object?> get props => [month, categoryId, limit];
}

class BudgetRemoved extends BudgetEvent {
  final String id;
  final DateTime month;
  const BudgetRemoved(this.id, this.month);
  @override
  List<Object?> get props => [id, month];
}

// ---- State --------------------------------------------------------------

class BudgetState extends Equatable {
  final DateTime month;
  final List<Budget> budgets;
  final int version;

  const BudgetState({
    required this.month,
    required this.budgets,
    this.version = 0,
  });

  Budget? get overall {
    for (final b in budgets) {
      if (b.categoryId == null) return b;
    }
    return null;
  }

  List<Budget> get perCategory => budgets.where((b) => b.categoryId != null).toList();

  Budget? forCategory(String id) {
    for (final b in budgets) {
      if (b.categoryId == id) return b;
    }
    return null;
  }

  @override
  List<Object?> get props => [month, version];
}

// ---- Bloc ---------------------------------------------------------------

class BudgetBloc extends Bloc<BudgetEvent, BudgetState> {
  final TxnRepository _repo;

  BudgetBloc(this._repo)
      : super(BudgetState(
          month: DateTime(DateTime.now().year, DateTime.now().month),
          budgets: const [],
        )) {
    on<BudgetLoaded>((e, emit) => emit(_load(e.month)));
    on<BudgetSet>(_onSet);
    on<BudgetRemoved>(_onRemoved);
  }

  BudgetState _load(DateTime month) {
    final m = DateTime(month.year, month.month);
    return BudgetState(
      month: m,
      budgets: _repo.budgetsForMonth(m),
      version: state.version + 1,
    );
  }

  Future<void> _onSet(BudgetSet e, Emitter<BudgetState> emit) async {
    await _repo.setBudget(month: e.month, categoryId: e.categoryId, limit: e.limit);
    emit(_load(e.month));
  }

  Future<void> _onRemoved(BudgetRemoved e, Emitter<BudgetState> emit) async {
    await _repo.deleteBudget(e.id);
    emit(_load(e.month));
  }
}
