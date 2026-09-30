import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_links.dart';
import '../../core/constants/features.dart';
import '../../core/theme/app_skin.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../logic/budget/budget_bloc.dart';
import '../../logic/theme/theme_bloc.dart';
import '../../logic/txns/txns_bloc.dart';
import 'auth_screen.dart';
import 'manage_categories_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _exportCsv(BuildContext context) async {
    final state = context.read<TxnsBloc>().state;
    if (state.all.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transactions to export')),
      );
      return;
    }
    final rows = <List<dynamic>>[
      ['Date', 'Type', 'Category', 'Amount', 'Note'],
      for (final t in state.all)
        [
          DateFormat('yyyy-MM-dd HH:mm').format(t.date),
          t.type,
          state.category(t.categoryId)?.name ?? t.categoryId,
          t.amount,
          t.note ?? '',
        ],
    ];
    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final file = File('${dir.path}/spendcraft_$stamp.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)], subject: 'SpendCraft export');
  }

  Future<void> _clearAll(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all data?'),
        content: const Text(
          'All transactions, budgets and custom categories on this device will be deleted. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete everything',
              style: TextStyle(color: context.skin.expense),
            ),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<TxnsBloc>().add(const TxnsCleared());
      context.read<BudgetBloc>().add(BudgetLoaded(DateTime.now()));
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('All data cleared')));
    }
  }

  Future<void> _pickCurrency(BuildContext context) async {
    const options = ['₹', '\$', '€', '£', '¥', 'AED', 'SGD'];
    final cubit = context.read<ThemeCubit>();
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => ListView(
        shrinkWrap: true,
        children: [
          for (final o in options)
            ListTile(
              title: Text(
                o,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              trailing: cubit.state.currency == o
                  ? Icon(Icons.check, color: context.skin.primary)
                  : null,
              onTap: () => Navigator.pop(context, o),
            ),
        ],
      ),
    );
    if (picked != null) {
      cubit.setCurrency(picked);
      if (context.mounted) context.read<TxnsBloc>().add(const TxnsLoaded());
    }
  }

  void _toggleDesign(BuildContext context) {
    final cubit = context.read<ThemeCubit>();
    final next = cubit.state.design == DesignSystem.foodDelivery
        ? DesignSystem.spendcraft
        : DesignSystem.foodDelivery;
    cubit.setDesign(next);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            next == DesignSystem.spendcraft
                ? 'Original SpendCraft UI enabled'
                : 'FoodDelivery design restored',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    final ok = await launchUrl(
      Uri.parse(AppLinks.privacyPolicy),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open ${AppLinks.privacyPolicy}'),
        ),
      );
    }
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    String? email,
  ) async {
    final skin = context.skin;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete your account?'),
        content: Text(
          'This permanently deletes ${email ?? 'your account'} and every transaction, '
          'budget and category synced to it. The copy on this phone is erased too.\n\n'
          'This cannot be undone. To keep your data, use Export to CSV first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete account',
              style: TextStyle(color: skin.expense),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<AuthBloc>().add(const AuthDeleteAccountRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final muted = skin.muted;

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (_, s) => s is AuthAccountDeleted || s is AuthDeleteFailed,
      listener: (context, s) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              s is AuthDeleteFailed
                  ? s.message
                  : 'Your account and all its data were deleted.',
            ),
            backgroundColor: s is AuthDeleteFailed ? skin.expense : null,
            duration: const Duration(seconds: 5),
          ),
        );
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            _SectionLabel(
              AppFeatures.cloudSync ? 'Account' : 'Your data',
              muted,
            ),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, auth) {
                final authBloc = context.read<AuthBloc>();
                if (auth is AuthLoading) {
                  return const Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                      title: Text('Working…'),
                    ),
                  );
                }
                if (auth is AuthAuthenticated) {
                  return Card(
                    margin: EdgeInsets.zero,
                    child: Column(
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: skin.primarySoft,
                            child: Icon(Icons.person, color: skin.primary),
                          ),
                          title: Text(
                            auth.user.email ?? 'Signed in',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: const Text('Syncing to cloud'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(Icons.logout, color: skin.expense),
                          title: Text(
                            'Sign out',
                            style: TextStyle(color: skin.expense),
                          ),
                          onTap: () =>
                              authBloc.add(const AuthSignOutRequested()),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(
                            Icons.person_remove_outlined,
                            color: skin.expense,
                          ),
                          title: Text(
                            'Delete account',
                            style: TextStyle(color: skin.expense),
                          ),
                          subtitle: const Text(
                            'Permanently remove your account and synced data',
                          ),
                          onTap: () =>
                              _confirmDeleteAccount(context, auth.user.email),
                        ),
                      ],
                    ),
                  );
                }
                return Card(
                  margin: EdgeInsets.zero,
                  color: skin.isFoodDelivery
                      ? skin.subtle
                      : skin.primary.withValues(alpha: 0.08),
                  child: ListTile(
                    leading: Icon(
                      AppFeatures.cloudSync
                          ? Icons.cloud_off_outlined
                          : Icons.phone_android_outlined,
                      color: skin.primary,
                    ),
                    title: Text(
                      AppFeatures.cloudSync
                          ? "You're in Guest mode"
                          : 'Stored on this device only',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      authBloc.isAvailable
                          ? 'Sign in to back up & sync your data.'
                          : AppFeatures.cloudSync
                          ? 'Data is stored only on this device.'
                          : 'No account needed — nothing leaves your phone. '
                                'Use Export to CSV to keep a backup.',
                    ),
                    trailing: authBloc.isAvailable
                        ? const Icon(Icons.chevron_right)
                        : null,
                    onTap: authBloc.isAvailable
                        ? () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AuthScreen(),
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            _SectionLabel('Appearance', muted),
            Card(
              margin: EdgeInsets.zero,
              child: BlocBuilder<ThemeCubit, ThemeState>(
                builder: (context, theme) => Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Row(
                        children: [
                          // Backdoor: 5 quick taps on the label toggle the
                          // original SpendCraft UI. Deliberately unlabelled.
                          Expanded(
                            child: _SecretTaps(
                              onTriggered: () => _toggleDesign(context),
                              child: const Row(
                                children: [
                                  Icon(Icons.brightness_6_outlined),
                                  SizedBox(width: 14),
                                  Text('Theme'),
                                ],
                              ),
                            ),
                          ),
                          SegmentedButton<ThemeMode>(
                            segments: const [
                              ButtonSegment(
                                value: ThemeMode.light,
                                icon: Icon(Icons.light_mode, size: 16),
                              ),
                              ButtonSegment(
                                value: ThemeMode.system,
                                icon: Icon(Icons.phone_android, size: 16),
                              ),
                              ButtonSegment(
                                value: ThemeMode.dark,
                                icon: Icon(Icons.dark_mode, size: 16),
                              ),
                            ],
                            selected: {theme.mode},
                            showSelectedIcon: false,
                            style: SegmentedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              selectedBackgroundColor: skin.primary,
                              selectedForegroundColor: skin.onPrimary,
                            ),
                            onSelectionChanged: (s) =>
                                context.read<ThemeCubit>().setMode(s.first),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.currency_rupee),
                      title: const Text('Currency symbol'),
                      trailing: Text(
                        theme.currency,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      onTap: () => _pickCurrency(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _SectionLabel('Data', muted),
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.category_outlined),
                    title: const Text('Manage categories'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ManageCategoriesScreen(),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.file_download_outlined),
                    title: const Text('Export to CSV'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _exportCsv(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      Icons.delete_forever_outlined,
                      color: skin.expense,
                    ),
                    title: Text(
                      'Clear all data',
                      style: TextStyle(color: skin.expense),
                    ),
                    onTap: () => _clearAll(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _SectionLabel('About', muted),
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('SpendCraft'),
                    subtitle: Text('Version 1.0.0'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.star_outline),
                    title: const Text('Rate app'),
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Coming soon on Play Store'),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('Privacy policy'),
                    trailing: const Icon(Icons.open_in_new, size: 18),
                    onTap: () => _openPrivacyPolicy(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// Counts rapid taps on [child]; fires [onTriggered] on the 5th tap.
/// A pause longer than 1.5s between taps starts the count over.
class _SecretTaps extends StatefulWidget {
  static const _taps = 5;
  static const _window = Duration(milliseconds: 1500);

  final Widget child;
  final VoidCallback onTriggered;
  const _SecretTaps({required this.child, required this.onTriggered});

  @override
  State<_SecretTaps> createState() => _SecretTapsState();
}

class _SecretTapsState extends State<_SecretTaps> {
  int _count = 0;
  DateTime? _last;

  void _onTap() {
    final now = DateTime.now();
    if (_last == null || now.difference(_last!) > _SecretTaps._window) {
      _count = 0;
    }
    _last = now;
    if (++_count >= _SecretTaps._taps) {
      _count = 0;
      HapticFeedback.mediumImpact();
      widget.onTriggered();
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: _onTap,
    child: widget.child,
  );
}
