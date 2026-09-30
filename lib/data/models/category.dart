import 'package:hive/hive.dart';

part 'category.g.dart';

@HiveType(typeId: 1)
class Category extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String icon; // emoji

  @HiveField(3)
  int colorIndex;

  @HiveField(4)
  String type; // 'income' | 'expense'

  @HiveField(5)
  bool isDefault;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorIndex,
    required this.type,
    this.isDefault = false,
  });

  bool get isExpense => type == 'expense';

  Map<String, dynamic> toSupabaseJson(String userId) => {
        'id': id,
        'user_id': userId,
        'name': name,
        'icon': icon,
        'color': colorIndex,
        'type': type,
      };

  factory Category.fromSupabaseJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String,
        colorIndex: (json['color'] as num).toInt(),
        type: json['type'] as String,
        isDefault: false,
      );
}
