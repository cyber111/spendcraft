import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_skin.dart';
import '../../core/utils/money_format.dart';
import '../../data/models/category.dart';

class CategorySlice {
  final Category? category;
  final double amount;
  const CategorySlice(this.category, this.amount);
}

class CategoryPie extends StatefulWidget {
  final List<CategorySlice> slices;
  final double total;
  const CategoryPie({super.key, required this.slices, required this.total});

  @override
  State<CategoryPie> createState() => _CategoryPieState();
}

class _CategoryPieState extends State<CategoryPie> {
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.slices.isEmpty || widget.total <= 0) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No expenses this month')),
      );
    }
    final skin = context.skin;
    final touchedSlice = _touched >= 0 && _touched < widget.slices.length
        ? widget.slices[_touched]
        : null;

    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: skin.isFoodDelivery ? 2 : 3,
              centerSpaceRadius: 62,
              startDegreeOffset: -90,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        response == null ||
                        response.touchedSection == null) {
                      _touched = -1;
                      return;
                    }
                    _touched = response.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              sections: List.generate(widget.slices.length, (i) {
                final s = widget.slices[i];
                final selected = i == _touched;
                // FoodDelivery is monochrome: shade by rank (biggest = ink)
                // instead of by category hue, so adjacent slices always differ.
                final color = skin.isFoodDelivery
                    ? skin.cat(i)
                    : s.category != null
                        ? skin.cat(s.category!.colorIndex)
                        : skin.muted;
                return PieChartSectionData(
                  value: s.amount,
                  color: color,
                  radius: selected ? 34 : 26,
                  showTitle: false,
                );
              }),
            ),
            duration: const Duration(milliseconds: 400),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (touchedSlice != null) ...[
                Text(touchedSlice.category?.icon ?? '📦',
                    style: const TextStyle(fontSize: 22)),
                Text(
                  MoneyFormat.compact(touchedSlice.amount),
                  style: skin.amount(size: 16),
                ),
                Text(
                  '${(touchedSlice.amount / widget.total * 100).toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 12, color: skin.muted),
                ),
              ] else ...[
                Text('Spent', style: TextStyle(fontSize: 12, color: skin.muted)),
                Text(
                  MoneyFormat.compact(widget.total),
                  style: skin.amount(size: 20),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
