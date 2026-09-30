import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_skin.dart';
import '../../core/utils/money_format.dart';

class MonthPoint {
  final DateTime month;
  final double income;
  final double expense;
  const MonthPoint(this.month, this.income, this.expense);
}

/// Grouped bar chart: income vs expense for the last N months.
class MonthlyBar extends StatelessWidget {
  final List<MonthPoint> points;
  const MonthlyBar({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final muted = skin.muted;
    final gridColor = skin.hairline;
    final barRadius = BorderRadius.vertical(top: Radius.circular(skin.isFoodDelivery ? 2 : 4));

    double maxY = 0;
    for (final p in points) {
      if (p.income > maxY) maxY = p.income;
      if (p.expense > maxY) maxY = p.expense;
    }
    if (maxY == 0) maxY = 1000;
    maxY = maxY * 1.2;

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => skin.card,
              tooltipBorder: BorderSide(color: gridColor),
              getTooltipItem: (group, gi, rod, ri) {
                final p = points[group.x.toInt()];
                final isIncome = ri == 0;
                return BarTooltipItem(
                  '${isIncome ? 'Income' : 'Expense'}\n${MoneyFormat.rupee(isIncome ? p.income : p.expense)}',
                  TextStyle(
                    color: isIncome ? skin.income : skin.expense,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (_) => FlLine(color: gridColor, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                interval: maxY / 4,
                getTitlesWidget: (v, meta) {
                  if (v == 0) return const SizedBox.shrink();
                  return Text(
                    MoneyFormat.compact(v, withSymbol: false),
                    style: TextStyle(fontSize: 10, color: muted),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  if (i < 0 || i >= points.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      DateFormat('MMM').format(points[i].month),
                      style: TextStyle(fontSize: 11, color: muted),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(points.length, (i) {
            final p = points[i];
            return BarChartGroupData(
              x: i,
              barsSpace: 4,
              barRods: [
                BarChartRodData(
                  toY: p.income,
                  color: skin.seriesIncome,
                  width: 10,
                  borderRadius: barRadius,
                ),
                BarChartRodData(
                  toY: p.expense,
                  color: skin.seriesExpense,
                  width: 10,
                  borderRadius: barRadius,
                ),
              ],
            );
          }),
        ),
        duration: const Duration(milliseconds: 400),
      ),
    );
  }
}
