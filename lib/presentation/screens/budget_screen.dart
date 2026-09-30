import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_skin.dart';
import '../../core/utils/money_format.dart';
import '../../data/models/category.dart';
import '../../logic/budget/budget_bloc.dart';
import '../../logic/txns/txns_bloc.dart';
import '../widgets/budget_progress.dart';
import '../widgets/month_selector.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  Future<void> _editBudget(
    BuildContext context, {
    required DateTime month,
    String? categoryId,
    double? current,
    List<Category>? pickFrom,
  }) async {
    final controller = TextEditingController(
        text: current != null ? current.toInt().toString() : '');
    String? chosenCat = categoryId;

    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                categoryId == null && pickFrom == null
                    ? 'Monthly budget'
                    : 'Category budget',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              if (pickFrom != null) ...[
                DropdownButtonFormField<String>(
                  initialValue: chosenCat,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: [
                    for (final c in pickFrom)
                      DropdownMenuItem(
                        value: c.id,
                        child: Text('${c.icon}  ${c.name}'),
                      ),
                  ],
                  onChanged: (v) => setSheet(() => chosenCat = v),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Limit',
                  prefixText: '${MoneyFormat.symbol} ',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  final v = double.tryParse(controller.text.trim());
                  if (v == null || v <= 0) return;
                  if (pickFrom != null && chosenCat == null) return;
                  Navigator.pop(ctx, v);
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null && context.mounted) {
      context.read<BudgetBloc>().add(BudgetSet(
            month: month,
            categoryId: pickFrom != null ? chosenCat : categoryId,
            limit: result,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final muted = skin.muted;

    return Scaffold(
      appBar: AppBar(title: const Text('Budget')),
      body: BlocBuilder<TxnsBloc, TxnsState>(
        builder: (context, txns) {
          return BlocBuilder<BudgetBloc, BudgetState>(
            builder: (context, budget) {
              // Keep budget month in sync with the txns month selector.
              if (budget.month != txns.month) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    context.read<BudgetBloc>().add(BudgetLoaded(txns.month));
                  }
                });
              }

              final spentTotal = txns.monthExpense;
              final spentByCat = <String, double>{};
              for (final t in txns.monthTxns.where((t) => t.isExpense)) {
                spentByCat[t.categoryId] = (spentByCat[t.categoryId] ?? 0) + t.amount;
              }
              final overall = budget.overall;
              final perCat = budget.perCategory;
              final expenseCats = txns.categories.values
                  .where((c) => c.isExpense && budget.forCategory(c.id) == null)
                  .toList();

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                children: [
                  MonthSelector(
                    month: txns.month,
                    onChanged: (m) => context.read<TxnsBloc>().add(TxnsMonthChanged(m)),
                  ),
                  const SizedBox(height: 8),
                  if (overall == null)
                    _SetOverallCard(
                      onTap: () => _editBudget(context, month: txns.month),
                      spent: spentTotal,
                    )
                  else
                    BudgetProgress(
                      title: 'Monthly budget',
                      icon: '🎯',
                      spent: spentTotal,
                      limit: overall.limitAmount,
                      onTap: () => _editBudget(context,
                          month: txns.month, current: overall.limitAmount),
                      onDelete: () => context
                          .read<BudgetBloc>()
                          .add(BudgetRemoved(overall.id, txns.month)),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Category budgets',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: expenseCats.isEmpty
                            ? null
                            : () => _editBudget(context,
                                month: txns.month, pickFrom: expenseCats),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  if (perCat.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'Set limits for specific categories\nlike Food or Shopping.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: muted, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    for (final b in perCat)
                      Builder(builder: (context) {
                        final c = txns.category(b.categoryId!);
                        return BudgetProgress(
                          title: c?.name ?? 'Category',
                          icon: c?.icon,
                          spent: spentByCat[b.categoryId] ?? 0,
                          limit: b.limitAmount,
                          onTap: () => _editBudget(context,
                              month: txns.month,
                              categoryId: b.categoryId,
                              current: b.limitAmount),
                          onDelete: () => context
                              .read<BudgetBloc>()
                              .add(BudgetRemoved(b.id, txns.month)),
                        );
                      }),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _SetOverallCard extends StatelessWidget {
  final VoidCallback onTap;
  final double spent;
  const _SetOverallCard({required this.onTap, required this.spent});

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: skin.cardRadius,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: skin.isFoodDelivery ? skin.subtle : skin.primary.withValues(alpha: 0.12),
                  borderRadius: skin.controlRadius,
                ),
                child: Icon(Icons.add_chart, color: skin.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Set a monthly budget',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                      'Spent ${MoneyFormat.rupee(spent)} so far this month',
                      style: TextStyle(fontSize: 12.5, color: skin.muted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
