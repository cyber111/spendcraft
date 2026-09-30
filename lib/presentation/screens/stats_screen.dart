import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_skin.dart';
import '../../core/utils/money_format.dart';
import '../../data/models/category.dart';
import '../../logic/txns/txns_bloc.dart';
import '../widgets/category_pie.dart';
import '../widgets/month_selector.dart';
import '../widgets/monthly_bar.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final muted = skin.muted;

    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: BlocBuilder<TxnsBloc, TxnsState>(
        builder: (context, state) {
          final monthTxns = state.monthTxns;
          final expense = state.monthExpense;
          final income = state.monthIncome;
          final savings = income - expense;

          // Expenses by category for this month.
          final byCat = <String, double>{};
          for (final t in monthTxns.where((t) => t.isExpense)) {
            byCat[t.categoryId] = (byCat[t.categoryId] ?? 0) + t.amount;
          }
          final slices = byCat.entries
              .map((e) => CategorySlice(state.category(e.key), e.value))
              .toList()
            ..sort((a, b) => b.amount.compareTo(a.amount));

          // Last 6 months, income vs expense.
          final points = <MonthPoint>[];
          for (var i = 5; i >= 0; i--) {
            final m = DateTime(state.month.year, state.month.month - i);
            double inc = 0, exp = 0;
            for (final t in state.all) {
              if (t.date.year == m.year && t.date.month == m.month) {
                if (t.isIncome) {
                  inc += t.amount;
                } else {
                  exp += t.amount;
                }
              }
            }
            points.add(MonthPoint(m, inc, exp));
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: [
              MonthSelector(
                month: state.month,
                onChanged: (m) => context.read<TxnsBloc>().add(TxnsMonthChanged(m)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _Total(label: 'Income', value: income, color: skin.income),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Total(label: 'Expense', value: expense, color: skin.expense),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Total(
                      label: 'Savings',
                      value: savings,
                      color: savings >= 0 ? skin.primary : skin.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'Spending by category',
                child: Column(
                  children: [
                    CategoryPie(slices: slices, total: expense),
                    if (slices.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      for (final (i, s) in slices.take(6).indexed)
                        _CatRow(slice: s, rank: i, total: expense, muted: muted),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'Last 6 months',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Legend(color: skin.seriesIncome, label: 'Income'),
                    const SizedBox(width: 10),
                    _Legend(color: skin.seriesExpense, label: 'Expense'),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, right: 8),
                  child: MonthlyBar(points: points),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Total extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _Total({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                MoneyFormat.compact(value),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  const _Section({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(context.skin.isFoodDelivery ? 1 : 3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

class _CatRow extends StatelessWidget {
  final CategorySlice slice;

  /// Position in the pie; FoodDelivery shades slices by rank, so the row
  /// swatch must use the same index to match its slice.
  final int rank;
  final double total;
  final Color muted;
  const _CatRow({
    required this.slice,
    required this.rank,
    required this.total,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    final Category? c = slice.category;
    final skin = context.skin;
    final color = skin.isFoodDelivery
        ? skin.cat(rank)
        : c != null
            ? skin.cat(c.colorIndex)
            : skin.muted;
    final pct = total > 0 ? slice.amount / total : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: skin.tint(color),
              borderRadius: skin.controlRadius,
            ),
            alignment: Alignment.center,
            child: Text(c?.icon ?? '📦', style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(c?.name ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                    ),
                    Text(MoneyFormat.rupee(slice.amount),
                        style: skin.amount(size: 13.5)),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(skin.isFoodDelivery ? 1 : 4),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: skin.isFoodDelivery ? 4 : 5,
                          backgroundColor: skin.isFoodDelivery
                              ? skin.subtle
                              : color.withValues(alpha: 0.12),
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 36,
                      child: Text('${(pct * 100).toStringAsFixed(0)}%',
                          textAlign: TextAlign.right,
                          style: TextStyle(fontSize: 11, color: muted)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
