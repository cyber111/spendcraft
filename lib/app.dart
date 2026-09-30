import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_skin.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/txn_repository.dart';
import 'logic/auth/auth_bloc.dart';
import 'logic/budget/budget_bloc.dart';
import 'logic/theme/theme_bloc.dart';
import 'logic/txns/txns_bloc.dart';
import 'presentation/screens/splash_screen.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class SpendCraftApp extends StatelessWidget {
  const SpendCraftApp({super.key});

  @override
  Widget build(BuildContext context) {
    final txnRepo = TxnRepository();
    final authRepo = AuthRepository();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: txnRepo),
        RepositoryProvider.value(value: authRepo),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ThemeCubit()),
          BlocProvider(create: (_) => AuthBloc(authRepo)..add(const AuthStarted())),
          BlocProvider(create: (_) => TxnsBloc(txnRepo)..add(const TxnsLoaded())),
          BlocProvider(
            create: (_) => BudgetBloc(txnRepo)..add(BudgetLoaded(DateTime.now())),
          ),
        ],
        child: BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, theme) {
            return MaterialApp(
              title: 'SpendCraft',
              debugShowCheckedModeBanner: false,
              navigatorKey: navigatorKey,
              theme: AppSkin.theme(theme.design, Brightness.light),
              darkTheme: AppSkin.theme(theme.design, Brightness.dark),
              themeMode: theme.mode,
              home: const SplashScreen(),
              builder: (context, child) => _AuthFlowListener(child: child!),
            );
          },
        ),
      ),
    );
  }
}

/// App-wide listener for auth transitions:
///  - asks "Upload your existing data?" after a fresh login
///  - reloads blocs once data has been pulled from the server
///  - reloads blocs after sign-out (local cache stays, we just re-read it)
class _AuthFlowListener extends StatelessWidget {
  final Widget child;
  const _AuthFlowListener({required this.child});

  Future<void> _askMigration(BuildContext context, AuthNeedsMigration state) async {
    final bloc = context.read<AuthBloc>();
    if (!state.hasLocalData) {
      bloc.add(const AuthMigrationDecided(false));
      return;
    }
    final ctx = navigatorKey.currentContext;
    if (ctx == null) {
      bloc.add(const AuthMigrationDecided(true));
      return;
    }
    final upload = await showDialog<bool>(
      context: ctx,
      barrierDismissible: false,
      builder: (dctx) => AlertDialog(
        title: const Text('Upload your existing data?'),
        content: const Text(
            'You have transactions saved on this device. Upload them to your account so they sync everywhere?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx, false),
            child: const Text('Discard local'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dctx, true),
            child: const Text('Upload'),
          ),
        ],
      ),
    );
    bloc.add(AuthMigrationDecided(upload ?? true));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) => prev.runtimeType != curr.runtimeType,
      listener: (context, state) {
        if (state is AuthNeedsMigration) {
          _askMigration(context, state);
        } else if (state is AuthAuthenticated || state is AuthGuest) {
          context.read<TxnsBloc>().add(const TxnsLoaded());
          context.read<BudgetBloc>().add(BudgetLoaded(context.read<TxnsBloc>().state.month));
        }
      },
      child: child,
    );
  }
}
