import 'package:hive/hive.dart';

part 'budget.g.dart';

@HiveType(typeId: 2)
class Budget extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String month; // 'YYYY-MM'

  @HiveField(2)
  String? categoryId; // null = overall monthly budget

  @HiveField(3)
  double limitAmount;

  Budget({
    required this.id,
    required this.month,
    this.categoryId,
    required this.limitAmount,
  });

  bool get isOverall => categoryId == null;

  Map<String, dynamic> toSupabaseJson(String userId) => {
        'id': id,
        'user_id': userId,
        'month': month,
        'category_id': categoryId,
        'limit_amount': limitAmount,
      };

  factory Budget.fromSupabaseJson(Map<String, dynamic> json) => Budget(
        id: json['id'] as String,
        month: json['month'] as String,
        categoryId: json['category_id'] as String?,
        limitAmount: (json['limit_amount'] as num).toDouble(),
      );
}
