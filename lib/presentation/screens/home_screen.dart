import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_skin.dart';
import '../../core/utils/date_grouping.dart';
import '../../data/local/hive_service.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../logic/txns/txns_bloc.dart';
import '../widgets/balance_card.dart';
import '../widgets/month_selector.dart';
import '../widgets/txn_tile.dart';
import 'add_txn_screen.dart';
import 'all_txns_screen.dart';
import 'auth_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _bannerDismissed = HiveService.guestBannerDismissed;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final muted = skin.muted;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<TxnsBloc, TxnsState>(
          builder: (context, state) {
            final monthTxns = state.monthTxns;
            final groups = DateGrouping.groupByDay(monthTxns.take(30).toList());
            final label = DateFormat('MMMM').format(state.month);

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Hello 👋', style: TextStyle(color: muted, fontSize: 13)),
                              const Text('SpendCraft',
                                  style: TextStyle(
                                      fontSize: 22, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, auth) {
                            if (auth is AuthAuthenticated) {
                              return CircleAvatar(
                                radius: 18,
                                backgroundColor: skin.primarySoft,
                                child: Icon(Icons.cloud_done_rounded,
                                    color: skin.primary, size: 20),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, auth) {
                      final authBloc = context.read<AuthBloc>();
                      if (auth is! AuthGuest || _bannerDismissed || !authBloc.isAvailable) {
                        return const SizedBox.shrink();
                      }
                      return _GuestBanner(
                        onSignIn: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AuthScreen()),
                        ),
                        onDismiss: () {
                          HiveService.guestBannerDismissed = true;
                          setState(() => _bannerDismissed = true);
                        },
                      );
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: MonthSelector(
                    month: state.month,
                    onChanged: (m) => context.read<TxnsBloc>().add(TxnsMonthChanged(m)),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: BalanceCard(
                      balance: state.monthBalance,
                      income: state.monthIncome,
                      expense: state.monthExpense,
                      monthLabel: label,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                    child: Row(
                      children: [
                        const Text('Recent transactions',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AllTxnsScreen()),
                          ),
                          child: const Text('See all'),
                        ),
                      ],
                    ),
                  ),
                ),
                if (monthTxns.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(muted: muted),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final group = groups[i];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                                child: Text(
                                  DateGrouping.dateHeader(group.key),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: muted,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              Card(
                                margin: EdgeInsets.zero,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  child: Column(
                                    children: [
                                      for (final t in group.value)
                                        TxnTile(
                                          txn: t,
                                          category: state.category(t.categoryId),
                                          onTap: () => Navigator.of(context).push(
                                            MaterialPageRoute(
                                                builder: (_) => AddTxnScreen(existing: t)),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ).animate().fadeIn(delay: (40 * i).ms, duration: 250.ms);
                        },
                        childCount: groups.length,
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

class _GuestBanner extends StatelessWidget {
  final VoidCallback onSignIn;
  final VoidCallback onDismiss;
  const _GuestBanner({required this.onSignIn, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: skin.isFoodDelivery
          ? skin.cardDecoration(color: skin.subtle)
          : BoxDecoration(
              color: skin.primary.withValues(alpha: 0.1),
              borderRadius: skin.controlRadius,
            ),
      child: Row(
        children: [
          Icon(Icons.cloud_upload_outlined, color: skin.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: onSignIn,
              child: const Text(
                'Sign in to back up your data',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onDismiss,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Color muted;
  const _EmptyState({required this.muted});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 80),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🧾', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text('No transactions yet',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 4),
          Text('Tap + to add your first one',
              style: TextStyle(color: muted, fontSize: 13)),
        ],
      ),
    );
  }
}
