import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonthSelector extends StatelessWidget {
  final DateTime month;
  final ValueChanged<DateTime> onChanged;
  const MonthSelector({super.key, required this.month, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrent = month.year == now.year && month.month == now.month;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: () => onChanged(DateTime(month.year, month.month - 1)),
        ),
        GestureDetector(
          onTap: isCurrent ? null : () => onChanged(DateTime(now.year, now.month)),
          child: SizedBox(
            width: 150,
            child: Text(
              DateFormat('MMMM yyyy').format(month),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: () => onChanged(DateTime(month.year, month.month + 1)),
        ),
      ],
    );
  }
}
