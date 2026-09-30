import 'package:flutter/material.dart';

import '../../core/theme/app_skin.dart';
import '../../core/utils/money_format.dart';

/// Progress bar: teal normally, amber above 80%, red when over.
class BudgetProgress extends StatelessWidget {
  final String title;
  final String? icon;
  final double spent;
  final double limit;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const BudgetProgress({
    super.key,
    required this.title,
    this.icon,
    required this.spent,
    required this.limit,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = limit > 0 ? spent / limit : 0.0;
    final skin = context.skin;
    final color = skin.budgetColor(ratio);
    final muted = skin.muted;
    final remaining = limit - spent;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: skin.cardRadius,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Text(icon!, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                  Text(
                    '${(ratio * 100).clamp(0, 999).toStringAsFixed(0)}%',
                    style: skin.amount(size: 14, color: color),
                  ),
                  if (onDelete != null)
                    IconButton(
                      icon: Icon(Icons.close, size: 18, color: muted),
                      onPressed: onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(skin.isFoodDelivery ? 2 : 8),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: ratio.clamp(0.0, 1.0)),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                  builder: (context, v, _) => LinearProgressIndicator(
                    value: v,
                    minHeight: skin.isFoodDelivery ? 6 : 10,
                    backgroundColor: skin.isFoodDelivery ? skin.subtle : color.withValues(alpha: 0.15),
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "You've spent ${MoneyFormat.rupee(spent)} of ${MoneyFormat.rupee(limit)}",
                      style: TextStyle(fontSize: 12.5, color: muted),
                    ),
                  ),
                  Text(
                    remaining >= 0
                        ? '${MoneyFormat.rupee(remaining)} left'
                        : '${MoneyFormat.rupee(-remaining)} over',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: remaining >= 0 ? muted : skin.expense,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
