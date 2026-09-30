import 'package:hive/hive.dart';

part 'txn.g.dart';

@HiveType(typeId: 0)
class Txn extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  double amount;

  @HiveField(2)
  String type; // 'income' | 'expense'

  @HiveField(3)
  String categoryId;

  @HiveField(4)
  String? note;

  @HiveField(5)
  DateTime date;

  @HiveField(6)
  DateTime updatedAt;

  @HiveField(7)
  bool synced; // false until pushed to Supabase

  Txn({
    required this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    this.note,
    required this.date,
    required this.updatedAt,
    this.synced = false,
  });

  bool get isExpense => type == 'expense';
  bool get isIncome => type == 'income';

  /// Signed value: negative for expense, positive for income.
  double get signed => isExpense ? -amount : amount;

  Map<String, dynamic> toSupabaseJson(String userId) => {
        'id': id,
        'user_id': userId,
        'amount': amount,
        'type': type,
        'category_id': categoryId,
        'note': note,
        'date': date.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };

  factory Txn.fromSupabaseJson(Map<String, dynamic> json) => Txn(
        id: json['id'] as String,
        amount: (json['amount'] as num).toDouble(),
        type: json['type'] as String,
        categoryId: json['category_id'] as String,
        note: json['note'] as String?,
        date: DateTime.parse(json['date'] as String).toLocal(),
        updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
        synced: true,
      );

  Txn copyWith({
    double? amount,
    String? type,
    String? categoryId,
    String? note,
    DateTime? date,
    DateTime? updatedAt,
    bool? synced,
  }) =>
      Txn(
        id: id,
        amount: amount ?? this.amount,
        type: type ?? this.type,
        categoryId: categoryId ?? this.categoryId,
        note: note ?? this.note,
        date: date ?? this.date,
        updatedAt: updatedAt ?? this.updatedAt,
        synced: synced ?? this.synced,
      );
}
