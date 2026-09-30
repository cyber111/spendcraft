import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_skin.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/money_format.dart';
import '../../data/models/txn.dart';
import '../../logic/txns/txns_bloc.dart';
import '../widgets/amount_pad.dart';
import '../widgets/category_picker.dart';

/// Add a new transaction, or edit [existing].
class AddTxnScreen extends StatefulWidget {
  final Txn? existing;
  const AddTxnScreen({super.key, this.existing});

  @override
  State<AddTxnScreen> createState() => _AddTxnScreenState();
}

class _AddTxnScreenState extends State<AddTxnScreen> {
  late String _type;
  late String _amountStr;
  String? _categoryId;
  late DateTime _date;
  late final TextEditingController _note;

  bool get _isEditing => widget.existing != null;

  double get _amount => double.tryParse(_amountStr) ?? 0;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = e?.type ?? 'expense';
    _amountStr = e != null ? _fmtInitial(e.amount) : '';
    _categoryId = e?.categoryId;
    _date = e?.date ?? DateTime.now();
    _note = TextEditingController(text: e?.note ?? '');
  }

  static String _fmtInitial(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toString();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _onKey(String k) {
    setState(() {
      if (k == 'del') {
        if (_amountStr.isNotEmpty) {
          _amountStr = _amountStr.substring(0, _amountStr.length - 1);
        }
      } else if (k == 'clear') {
        _amountStr = '';
      } else if (k == '.') {
        if (!_amountStr.contains('.')) {
          _amountStr = _amountStr.isEmpty ? '0.' : '$_amountStr.';
        }
      } else {
        if (_amountStr == '0') _amountStr = '';
        if (_amountStr.contains('.')) {
          final decimals = _amountStr.split('.')[1];
          if (decimals.length >= 2) return;
        } else if (_amountStr.length >= 9) {
          return;
        }
        _amountStr += k;
      }
    });
  }

  void _setType(String t) {
    if (t == _type) return;
    setState(() {
      _type = t;
      _categoryId = null;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _date = DateTime(picked.year, picked.month, picked.day,
            _date.hour, _date.minute);
      });
    }
  }

  void _save() {
    if (_amount <= 0) {
      _snack('Enter an amount');
      return;
    }
    if (_categoryId == null) {
      _snack('Pick a category');
      return;
    }
    final bloc = context.read<TxnsBloc>();
    if (_isEditing) {
      final t = widget.existing!;
      t.amount = _amount;
      t.type = _type;
      t.categoryId = _categoryId!;
      t.note = _note.text;
      t.date = _date;
      bloc.add(TxnUpdated(t));
    } else {
      bloc.add(TxnAdded(
        amount: _amount,
        type: _type,
        categoryId: _categoryId!,
        note: _note.text,
        date: _date,
      ));
    }
    Navigator.of(context).pop();
  }

  void _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: context.skin.expense)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      context.read<TxnsBloc>().add(TxnDeleted(widget.existing!.id));
      Navigator.of(context).pop();
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = _type == 'expense';
    final skin = context.skin;
    final accent = isExpense ? skin.expense : skin.income;
    final muted = skin.muted;
    // FoodDelivery reserves coloured fills for destructive actions → ink CTA.
    final ctaFill = skin.isFoodDelivery ? skin.primary : accent;
    final now = DateTime.now();
    final isToday = _date.year == now.year && _date.month == now.month && _date.day == now.day;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit transaction' : 'Add transaction'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: Icon(Icons.delete_outline, color: skin.expense),
              onPressed: _delete,
            ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<TxnsBloc, TxnsState>(
          builder: (context, state) {
            final cats = state.categories.values.where((c) => c.type == _type).toList();
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        _TypeToggle(type: _type, onChanged: _setType),
                        const SizedBox(height: 22),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(MoneyFormat.symbol,
                                    style: AppTheme.amountStyle(context,
                                        size: 30, color: muted)),
                                const SizedBox(width: 4),
                                Text(
                                  _amountStr.isEmpty ? '0' : _amountStr,
                                  style: AppTheme.amountStyle(context,
                                      size: 52, color: _amountStr.isEmpty ? muted : accent),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_amount > 0)
                          Text(
                            MoneyFormat.rupee(_amount),
                            style: TextStyle(color: muted, fontSize: 13),
                          ),
                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                            child: Text('Category',
                                style: TextStyle(
                                    color: muted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                        CategoryPicker(
                          categories: cats,
                          selectedId: _categoryId,
                          onSelected: (id) => setState(() => _categoryId = id),
                        ),
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Expanded(
                                child: _Chip(
                                  icon: Icons.calendar_today_outlined,
                                  label: isToday
                                      ? 'Today'
                                      : DateFormat('d MMM yyyy').format(_date),
                                  onTap: _pickDate,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: _note,
                                  textCapitalization: TextCapitalization.sentences,
                                  decoration: const InputDecoration(
                                    hintText: 'Add a note',
                                    prefixIcon: Icon(Icons.notes, size: 20),
                                    isDense: true,
                                    contentPadding:
                                        EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                AmountPad(onKey: _onKey),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: ctaFill,
                        foregroundColor: skin.onPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                skin.isFoodDelivery ? skin.radiusControl : 16)),
                      ),
                      child: Text(
                        _isEditing ? 'Save changes' : 'Save ${isExpense ? 'expense' : 'income'}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  final String type;
  final ValueChanged<String> onChanged;
  const _TypeToggle({required this.type, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final fd = skin.isFoodDelivery;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: fd ? skin.card : skin.subtle,
        borderRadius: skin.controlRadius,
        border: fd ? Border.all(color: skin.controlBorder) : null,
      ),
      child: Row(
        children: [
          _seg(skin, 'Expense', 'expense', fd ? skin.primary : skin.expense),
          _seg(skin, 'Income', 'income', fd ? skin.primary : skin.income),
        ],
      ),
    );
  }

  Widget _seg(AppSkin skin, String label, String value, Color color) {
    final selected = type == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(skin.isFoodDelivery ? 2 : 11),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? skin.onPrimary : (skin.isFoodDelivery ? skin.muted : color),
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Chip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final shape = RoundedRectangleBorder(
      borderRadius: skin.controlRadius,
      side: skin.isFoodDelivery ? BorderSide(color: skin.controlBorder) : BorderSide.none,
    );
    return Material(
      color: skin.isFoodDelivery ? skin.card : skin.subtle,
      shape: shape,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          child: Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
