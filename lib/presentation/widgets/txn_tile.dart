import 'package:flutter/material.dart';

import '../../core/theme/app_skin.dart';
import '../../core/utils/money_format.dart';
import '../../data/models/category.dart';
import '../../data/models/txn.dart';

class TxnTile extends StatelessWidget {
  final Txn txn;
  final Category? category;
  final VoidCallback? onTap;

  const TxnTile({super.key, required this.txn, this.category, this.onTap});

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final color = category != null ? skin.cat(category!.colorIndex) : skin.muted;
    final amountColor = txn.isExpense ? skin.expense : skin.income;
    final muted = skin.muted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: skin.controlRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: skin.tint(color),
                  borderRadius: skin.controlRadius,
                ),
                alignment: Alignment.center,
                child: Text(
                  category?.icon ?? '❓',
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category?.name ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (txn.note != null && txn.note!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          txn.note!,
                          style: TextStyle(color: muted, fontSize: 12.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${txn.isExpense ? '-' : '+'}${MoneyFormat.rupee(txn.amount)}',
                style: skin.amount(size: 15, color: amountColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
