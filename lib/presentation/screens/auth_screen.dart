import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/supabase_config.dart';
import '../../core/theme/app_skin.dart';
import '../../logic/auth/auth_bloc.dart';
import 'main_shell.dart';

class AuthScreen extends StatefulWidget {
  /// When true, "Skip" replaces this screen with the main shell instead of
  /// popping back.
  final bool fromOnboarding;
  const AuthScreen({super.key, this.fromOnboarding = false});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isSignUp = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _skip() {
    context.read<AuthBloc>().add(const AuthContinueAsGuest());
    if (widget.fromOnboarding) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const MainShell()));
    } else {
      Navigator.of(context).pop();
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final bloc = context.read<AuthBloc>();
    if (_isSignUp) {
      bloc.add(AuthSignUpRequested(_email.text, _password.text));
    } else {
      bloc.add(AuthSignInRequested(_email.text, _password.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthBloc>();
    final skin = context.skin;
    final muted = skin.muted;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: skin.expense,
            ),
          );
        } else if (state is AuthConfirmEmail) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Check ${state.email} to confirm your account, then sign in.',
              ),
              duration: const Duration(seconds: 5),
            ),
          );
          setState(() => _isSignUp = false);
        } else if (state is AuthNeedsMigration || state is AuthAuthenticated) {
          // The app-level listener handles the migration prompt. Just leave.
          if (widget.fromOnboarding) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainShell()),
            );
          } else {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: widget.fromOnboarding
              ? null
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
          actions: [
            TextButton(onPressed: _skip, child: const Text('Skip for now')),
          ],
        ),
        body: SafeArea(
          child: !auth.isAvailable
              ? _NotConfigured(onSkip: _skip)
              : BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final loading = state is AuthLoading;
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _isSignUp ? 'Create account' : 'Welcome back',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _isSignUp
                                  ? 'Back up and sync your expenses across devices.'
                                  : 'Sign in to sync your data.',
                              style: TextStyle(color: muted),
                            ),
                            const SizedBox(height: 28),
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.mail_outline),
                              ),
                              validator: (v) {
                                if (v == null ||
                                    !v.contains('@') ||
                                    !v.contains('.')) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _password,
                              obscureText: _obscure,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.length < 6) {
                                  return 'At least 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 22),
                            SizedBox(
                              height: 52,
                              child: FilledButton(
                                onPressed: loading ? null : _submit,
                                style: FilledButton.styleFrom(
                                  backgroundColor: skin.primary,
                                  foregroundColor: skin.onPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: skin.controlRadius,
                                  ),
                                ),
                                child: loading
                                    ? SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: skin.onPrimary,
                                        ),
                                      )
                                    : Text(
                                        _isSignUp ? 'Sign Up' : 'Sign In',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                            // Hidden until the Google provider is configured in Supabase.
                            if (SupabaseConfig.googleSignInEnabled) ...[
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  const Expanded(child: Divider()),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text(
                                      'or',
                                      style: TextStyle(color: muted),
                                    ),
                                  ),
                                  const Expanded(child: Divider()),
                                ],
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                height: 52,
                                child: OutlinedButton.icon(
                                  onPressed: loading
                                      ? null
                                      : () => context.read<AuthBloc>().add(
                                          const AuthGoogleRequested(),
                                        ),
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: skin.controlRadius,
                                    ),
                                  ),
                                  icon: const Text(
                                    'G',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF4285F4),
                                    ),
                                  ),
                                  label: const Text(
                                    'Continue with Google',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            Center(
                              child: TextButton(
                                onPressed: () =>
                                    setState(() => _isSignUp = !_isSignUp),
                                child: Text(
                                  _isSignUp
                                      ? 'Already have an account? Sign In'
                                      : "Don't have an account? Sign Up",
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _NotConfigured extends StatelessWidget {
  final VoidCallback onSkip;
  const _NotConfigured({required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('☁️', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          const Text(
            'Cloud sync not configured',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'This build has no Supabase credentials. Add them to '
            'lib/core/constants/supabase_config.dart to enable sign-in.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: onSkip,
            style: FilledButton.styleFrom(
              backgroundColor: context.skin.primary,
              foregroundColor: context.skin.onPrimary,
            ),
            child: const Text('Continue as Guest'),
          ),
        ],
      ),
    );
  }
}
