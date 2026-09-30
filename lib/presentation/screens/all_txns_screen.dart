import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_skin.dart';
import '../../core/utils/date_grouping.dart';
import '../../core/utils/money_format.dart';
import '../../data/models/txn.dart';
import '../../logic/txns/txns_bloc.dart';
import '../widgets/txn_tile.dart';
import 'add_txn_screen.dart';

class AllTxnsScreen extends StatefulWidget {
  const AllTxnsScreen({super.key});

  @override
  State<AllTxnsScreen> createState() => _AllTxnsScreenState();
}

class _AllTxnsScreenState extends State<AllTxnsScreen> {
  final _search = TextEditingController();
  String _query = '';
  String? _type; // null = all
  String? _categoryId; // null = all
  DateTime? _month; // null = all time

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Txn> _filter(TxnsState state) {
    final q = _query.trim().toLowerCase();
    return state.all.where((t) {
      if (_type != null && t.type != _type) return false;
      if (_categoryId != null && t.categoryId != _categoryId) return false;
      if (_month != null &&
          (t.date.year != _month!.year || t.date.month != _month!.month)) {
        return false;
      }
      if (q.isNotEmpty) {
        final cat = state.category(t.categoryId)?.name.toLowerCase() ?? '';
        final note = t.note?.toLowerCase() ?? '';
        if (!note.contains(q) && !cat.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _month ?? now,
      firstDate: DateTime(2015),
      lastDate: DateTime(now.year + 1),
      helpText: 'Pick any day in the month',
    );
    if (picked != null) {
      setState(() => _month = DateTime(picked.year, picked.month));
    }
  }

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final muted = skin.muted;

    return Scaffold(
      appBar: AppBar(title: const Text('All transactions')),
      body: BlocBuilder<TxnsBloc, TxnsState>(
        builder: (context, state) {
          final list = _filter(state);
          final groups = DateGrouping.groupByDay(list);
          final total = list.fold(0.0, (s, t) => s + t.signed);
          final cats = state.categories.values.toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextField(
                  controller: _search,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search note or category',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _search.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                  ),
                ),
              ),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _FilterChip(
                      label: _month == null ? 'All time' : DateFormat('MMM yyyy').format(_month!),
                      icon: Icons.calendar_month_outlined,
                      active: _month != null,
                      onTap: _pickMonth,
                      onClear: _month != null ? () => setState(() => _month = null) : null,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: _type == null ? 'All types' : (_type == 'expense' ? 'Expense' : 'Income'),
                      icon: Icons.swap_vert,
                      active: _type != null,
                      onTap: () => setState(() {
                        _type = _type == null
                            ? 'expense'
                            : (_type == 'expense' ? 'income' : null);
                      }),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: _categoryId == null
                          ? 'All categories'
                          : (state.category(_categoryId!)?.name ?? 'Category'),
                      icon: Icons.category_outlined,
                      active: _categoryId != null,
                      onTap: () async {
                        final picked = await showModalBottomSheet<String>(
                          context: context,
                          showDragHandle: true,
                          builder: (_) => ListView(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.all_inclusive),
                                title: const Text('All categories'),
                                onTap: () => Navigator.pop(context, '__all__'),
                              ),
                              for (final c in cats)
                                ListTile(
                                  leading: Text(c.icon, style: const TextStyle(fontSize: 22)),
                                  title: Text(c.name),
                                  trailing: Text(c.type,
                                      style: TextStyle(fontSize: 11, color: muted)),
                                  onTap: () => Navigator.pop(context, c.id),
                                ),
                            ],
                          ),
                        );
                        if (picked != null) {
                          setState(() => _categoryId = picked == '__all__' ? null : picked);
                        }
                      },
                      onClear: _categoryId != null
                          ? () => setState(() => _categoryId = null)
                          : null,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Row(
                  children: [
                    Text('${list.length} transactions',
                        style: TextStyle(fontSize: 12, color: muted)),
                    const Spacer(),
                    Text(
                      'Net ${MoneyFormat.rupee(total)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: total >= 0 ? skin.income : skin.expense,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: list.isEmpty
                    ? Center(
                        child: Text('Nothing matches', style: TextStyle(color: muted)))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: groups.length,
                        itemBuilder: (context, i) {
                          final g = groups[i];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                                child: Text(
                                  DateGrouping.dateHeader(g.key),
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: muted),
                                ),
                              ),
                              Card(
                                margin: EdgeInsets.zero,
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  children: [
                                    for (final t in g.value)
                                      Dismissible(
                                        key: ValueKey(t.id),
                                        direction: DismissDirection.endToStart,
                                        background: Container(
                                          color: skin.expense,
                                          alignment: Alignment.centerRight,
                                          padding: const EdgeInsets.only(right: 20),
                                          child: const Icon(Icons.delete_outline,
                                              color: Colors.white),
                                        ),
                                        confirmDismiss: (_) async {
                                          return await showDialog<bool>(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: const Text('Delete transaction?'),
                                                  actions: [
                                                    TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(ctx, false),
                                                        child: const Text('Cancel')),
                                                    TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(ctx, true),
                                                        child: Text('Delete',
                                                            style: TextStyle(
                                                                color: skin.expense))),
                                                  ],
                                                ),
                                              ) ??
                                              false;
                                        },
                                        onDismissed: (_) =>
                                            context.read<TxnsBloc>().add(TxnDeleted(t.id)),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 10),
                                          child: TxnTile(
                                            txn: t,
                                            category: state.category(t.categoryId),
                                            onTap: () => Navigator.of(context).push(
                                              MaterialPageRoute(
                                                  builder: (_) => AddTxnScreen(existing: t)),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final fd = skin.isFoodDelivery;
    // FoodDelivery chip: 4px radius, strong outline; selected = ink fill.
    final fg = active ? (fd ? skin.onPrimary : skin.primary) : null;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(fd ? skin.radiusControl : 20),
      side: fd && !active ? BorderSide(color: skin.controlBorder) : BorderSide.none,
    );
    return Material(
      color: active ? (fd ? skin.primary : skin.primarySoft) : skin.card,
      shape: shape,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 8, 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  )),
              if (onClear != null)
                GestureDetector(
                  onTap: onClear,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(Icons.close, size: 14, color: fg),
                  ),
                )
              else
                const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}
