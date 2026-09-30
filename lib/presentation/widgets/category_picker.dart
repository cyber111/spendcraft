import 'package:flutter/material.dart';

import '../../core/theme/app_skin.dart';
import '../../data/models/category.dart';

/// Horizontal scrollable category chips. Tap to select.
class CategoryPicker extends StatelessWidget {
  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  const CategoryPicker({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final c = categories[i];
          final selected = c.id == selectedId;
          final color = skin.emphasis(skin.cat(c.colorIndex));
          return GestureDetector(
            onTap: () => onSelected(c.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 76,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: selected ? skin.tint(color) : skin.card,
                borderRadius: skin.cardRadius,
                border: Border.all(
                  color: selected ? color : skin.cardBorder,
                  width: selected ? (skin.isFoodDelivery ? 2 : 1.8) : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(c.icon, style: const TextStyle(fontSize: 26)),
                  const SizedBox(height: 6),
                  Text(
                    c.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? color : skin.muted,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
