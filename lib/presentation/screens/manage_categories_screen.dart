import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_skin.dart';
import '../../data/models/category.dart';
import '../../logic/txns/txns_bloc.dart';

class ManageCategoriesScreen extends StatelessWidget {
  const ManageCategoriesScreen({super.key});

  Future<void> _edit(BuildContext context, {Category? existing, String type = 'expense'}) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final icon = TextEditingController(text: existing?.icon ?? '🏷️');
    int colorIndex = existing?.colorIndex ?? 0;
    String catType = existing?.type ?? type;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(existing == null ? 'New category' : 'Edit category',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    width: 72,
                    child: TextField(
                      controller: icon,
                      textAlign: TextAlign.center,
                      maxLength: 2,
                      style: const TextStyle(fontSize: 24),
                      decoration: const InputDecoration(counterText: '', hintText: '🏷️'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: name,
                      autofocus: existing == null,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (existing == null)
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'expense', label: Text('Expense')),
                    ButtonSegment(value: 'income', label: Text('Income')),
                  ],
                  selected: {catType},
                  onSelectionChanged: (s) => setSheet(() => catType = s.first),
                ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(AppColors.catColors.length, (i) {
                  final selected = i == colorIndex;
                  return GestureDetector(
                    onTap: () => setSheet(() => colorIndex = i),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.catColors[i],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: selected
                            ? [BoxShadow(color: AppColors.catColors[i], blurRadius: 6)]
                            : null,
                      ),
                      child: selected
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : null,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  if (name.text.trim().isEmpty) return;
                  Navigator.pop(ctx, true);
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

    if (ok != true || !context.mounted) return;
    final bloc = context.read<TxnsBloc>();
    final emoji = icon.text.trim().isEmpty ? '🏷️' : icon.text.trim();
    if (existing == null) {
      bloc.add(CategoryAdded(
        name: name.text,
        icon: emoji,
        colorIndex: colorIndex,
        type: catType,
      ));
    } else {
      existing.name = name.text.trim();
      existing.icon = emoji;
      existing.colorIndex = colorIndex;
      bloc.add(CategoryUpdated(existing));
    }
  }

  Future<void> _delete(BuildContext context, Category c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${c.name}"?'),
        content: const Text("Its transactions will be moved to 'Other'."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: context.skin.expense)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<TxnsBloc>().add(CategoryDeleted(c.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final muted = skin.muted;

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context),
        backgroundColor: skin.primary,
        foregroundColor: skin.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('New'),
      ),
      body: BlocBuilder<TxnsBloc, TxnsState>(
        builder: (context, state) {
          final expense = state.categories.values.where((c) => c.isExpense).toList();
          final income = state.categories.values.where((c) => !c.isExpense).toList();

          Widget tile(Category c) => ListTile(
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: skin.tint(skin.cat(c.colorIndex)),
                    borderRadius: skin.controlRadius,
                  ),
                  alignment: Alignment.center,
                  child: Text(c.icon, style: const TextStyle(fontSize: 20)),
                ),
                title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: c.isDefault
                    ? Text('Default', style: TextStyle(fontSize: 11, color: muted))
                    : null,
                trailing: c.isDefault
                    ? IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => _edit(context, existing: c),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () => _edit(context, existing: c),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline,
                                size: 20, color: skin.expense),
                            onPressed: () => _delete(context, c),
                          ),
                        ],
                      ),
              );

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                child: Text('EXPENSE',
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700, color: muted, letterSpacing: 0.8)),
              ),
              Card(
                margin: EdgeInsets.zero,
                child: Column(children: [for (final c in expense) tile(c)]),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                child: Text('INCOME',
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700, color: muted, letterSpacing: 0.8)),
              ),
              Card(
                margin: EdgeInsets.zero,
                child: Column(children: [for (final c in income) tile(c)]),
              ),
            ],
          );
        },
      ),
    );
  }
}
