import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_skin.dart';
import '../../core/utils/money_format.dart';

/// Month summary: three equal cards in a row — Income · Expense · Balance.
class BalanceCard extends StatelessWidget {
  final double balance;
  final double income;
  final double expense;

  /// e.g. "September" — used for screen-reader labels.
  final String monthLabel;

  const BalanceCard({
    super.key,
    required this.balance,
    required this.income,
    required this.expense,
    required this.monthLabel,
  });

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final cards = [
      _SummaryCard(
        label: 'Income',
        value: income,
        icon: Icons.arrow_downward_rounded,
        accent: skin.income,
        semantics: '$monthLabel income',
      ),
      _SummaryCard(
        label: 'Expense',
        value: expense,
        icon: Icons.arrow_upward_rounded,
        accent: skin.expense,
        semantics: '$monthLabel expense',
      ),
      _SummaryCard(
        label: 'Balance',
        value: balance,
        icon: Icons.account_balance_wallet_outlined,
        // Ink when healthy, red when the month is in the negative.
        accent: balance < 0 ? skin.expense : skin.text,
        semantics: '$monthLabel balance',
        // SpendCraft's original look keeps its gradient on the headline number.
        hero: skin.heroGradient != null,
      ),
    ];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: cards[i]
                  .animate()
                  .fadeIn(duration: 300.ms, delay: (60 * i).ms)
                  .slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final Color accent;
  final String semantics;
  final bool hero;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.semantics,
    this.hero = false,
  });

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final fd = skin.isFoodDelivery;
    final fg = hero ? skin.heroFg : accent;
    final muted = hero ? skin.heroFgMuted : skin.muted;

    return Semantics(
      label: '$semantics ${MoneyFormat.rupee(value)}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        decoration: BoxDecoration(
          color: hero ? null : skin.card,
          gradient: hero ? skin.heroGradient : null,
          borderRadius: skin.cardRadius,
          border: skin.cardBorder.a == 0 ? null : Border.all(color: skin.cardBorder),
          boxShadow: skin.shadows
              ? [
                  BoxShadow(
                    color: (hero ? skin.primary : Colors.black)
                        .withValues(alpha: hero ? 0.28 : 0.05),
                    blurRadius: hero ? 18 : 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: hero
                    ? Colors.white.withValues(alpha: 0.2)
                    : (fd ? skin.subtle : accent.withValues(alpha: 0.12)),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 15, color: hero ? skin.heroFg : accent),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: muted, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                MoneyFormat.rupee(value),
                maxLines: 1,
                style: skin.amount(size: 18, color: fg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
