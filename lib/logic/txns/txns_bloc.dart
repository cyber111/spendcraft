import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/category.dart';
import '../../data/models/txn.dart';
import '../../data/repositories/txn_repository.dart';

// ---- Events -------------------------------------------------------------

abstract class TxnsEvent extends Equatable {
  const TxnsEvent();
  @override
  List<Object?> get props => [];
}

class TxnsLoaded extends TxnsEvent {
  const TxnsLoaded();
}

class TxnsMonthChanged extends TxnsEvent {
  final DateTime month;
  const TxnsMonthChanged(this.month);
  @override
  List<Object?> get props => [month];
}

class TxnAdded extends TxnsEvent {
  final double amount;
  final String type;
  final String categoryId;
  final String? note;
  final DateTime date;
  const TxnAdded({
    required this.amount,
    required this.type,
    required this.categoryId,
    this.note,
    required this.date,
  });
  @override
  List<Object?> get props => [amount, type, categoryId, note, date];
}

class TxnUpdated extends TxnsEvent {
  final Txn txn;
  const TxnUpdated(this.txn);
  @override
  List<Object?> get props => [txn.id, txn.updatedAt];
}

class TxnDeleted extends TxnsEvent {
  final String id;
  const TxnDeleted(this.id);
  @override
  List<Object?> get props => [id];
}

class CategoryAdded extends TxnsEvent {
  final String name;
  final String icon;
  final int colorIndex;
  final String type;
  const CategoryAdded({
    required this.name,
    required this.icon,
    required this.colorIndex,
    required this.type,
  });
  @override
  List<Object?> get props => [name, icon, colorIndex, type];
}

class CategoryUpdated extends TxnsEvent {
  final Category category;
  const CategoryUpdated(this.category);
  @override
  List<Object?> get props => [category.id, category.name, category.icon, category.colorIndex];
}

class CategoryDeleted extends TxnsEvent {
  final String id;
  const CategoryDeleted(this.id);
  @override
  List<Object?> get props => [id];
}

class TxnsCleared extends TxnsEvent {
  const TxnsCleared();
}

// ---- State --------------------------------------------------------------

class TxnsState extends Equatable {
  final List<Txn> all;
  final Map<String, Category> categories;
  final DateTime month;
  final int version; // bumps on every change so equality always differs

  const TxnsState({
    required this.all,
    required this.categories,
    required this.month,
    this.version = 0,
  });

  List<Txn> get monthTxns => all
      .where((t) => t.date.year == month.year && t.date.month == month.month)
      .toList();

  double get monthIncome =>
      monthTxns.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);

  double get monthExpense =>
      monthTxns.where((t) => t.isExpense).fold(0.0, (s, t) => s + t.amount);

  double get monthBalance => monthIncome - monthExpense;

  Category? category(String id) => categories[id];

  TxnsState copyWith({
    List<Txn>? all,
    Map<String, Category>? categories,
    DateTime? month,
  }) =>
      TxnsState(
        all: all ?? this.all,
        categories: categories ?? this.categories,
        month: month ?? this.month,
        version: version + 1,
      );

  @override
  List<Object?> get props => [version, month];
}

// ---- Bloc ---------------------------------------------------------------

class TxnsBloc extends Bloc<TxnsEvent, TxnsState> {
  final TxnRepository _repo;

  TxnsBloc(this._repo)
      : super(TxnsState(
          all: const [],
          categories: const {},
          month: DateTime(DateTime.now().year, DateTime.now().month),
        )) {
    on<TxnsLoaded>((e, emit) => emit(_reload()));
    on<TxnsMonthChanged>((e, emit) => emit(_reload(month: DateTime(e.month.year, e.month.month))));
    on<TxnAdded>(_onAdded);
    on<TxnUpdated>(_onUpdated);
    on<TxnDeleted>(_onDeleted);
    on<CategoryAdded>(_onCatAdded);
    on<CategoryUpdated>(_onCatUpdated);
    on<CategoryDeleted>(_onCatDeleted);
    on<TxnsCleared>(_onCleared);
  }

  TxnsState _reload({DateTime? month}) {
    final cats = {for (final c in _repo.allCategories()) c.id: c};
    return state.copyWith(all: _repo.allTxns(), categories: cats, month: month);
  }

  Future<void> _onAdded(TxnAdded e, Emitter<TxnsState> emit) async {
    await _repo.addTxn(
      amount: e.amount,
      type: e.type,
      categoryId: e.categoryId,
      note: e.note,
      date: e.date,
    );
    emit(_reload());
  }

  Future<void> _onUpdated(TxnUpdated e, Emitter<TxnsState> emit) async {
    await _repo.updateTxn(e.txn);
    emit(_reload());
  }

  Future<void> _onDeleted(TxnDeleted e, Emitter<TxnsState> emit) async {
    await _repo.deleteTxn(e.id);
    emit(_reload());
  }

  Future<void> _onCatAdded(CategoryAdded e, Emitter<TxnsState> emit) async {
    await _repo.addCategory(
      name: e.name,
      icon: e.icon,
      colorIndex: e.colorIndex,
      type: e.type,
    );
    emit(_reload());
  }

  Future<void> _onCatUpdated(CategoryUpdated e, Emitter<TxnsState> emit) async {
    await _repo.updateCategory(e.category);
    emit(_reload());
  }

  Future<void> _onCatDeleted(CategoryDeleted e, Emitter<TxnsState> emit) async {
    await _repo.deleteCategory(e.id);
    emit(_reload());
  }

  Future<void> _onCleared(TxnsCleared e, Emitter<TxnsState> emit) async {
    await _repo.clearAll();
    emit(_reload());
  }
}
