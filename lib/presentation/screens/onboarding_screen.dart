import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/features.dart';
import '../../core/theme/app_skin.dart';
import '../../data/local/hive_service.dart';
import '../../logic/auth/auth_bloc.dart';
import 'auth_screen.dart';
import 'main_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = [
    _Slide(
      emoji: '⚡',
      title: 'Track spending in seconds',
      body: 'A fast number pad and one-tap categories make logging expenses effortless.',
    ),
    _Slide(
      emoji: '📊',
      title: 'See where your money goes',
      body: 'Clear charts, monthly breakdowns and budgets that warn you before you overspend.',
    ),
    _Slide(
      emoji: '🔒',
      title: 'Private by default',
      body: AppFeatures.cloudSync
          ? 'Everything stays on your phone. Sign in only if you want backup and sync across devices.'
          : 'Everything stays on your phone. No account, no sign-up — your data never leaves your device.',
    ),
  ];

  void _finish({required bool signIn}) {
    HiveService.onboarded = true;
    if (signIn) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const AuthScreen(fromOnboarding: true),
        ),
      );
    } else {
      context.read<AuthBloc>().add(const AuthContinueAsGuest());
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const MainShell()));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _finish(signIn: false),
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _slides[i],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _page ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _page
                        ? context.skin.primary
                        : context.skin.primary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(
                      context.skin.isFoodDelivery ? 1 : 4,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: isLast
                  ? Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            onPressed: () => _finish(signIn: false),
                            style: FilledButton.styleFrom(
                              backgroundColor: context.skin.primary,
                              foregroundColor: context.skin.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: context.skin.controlRadius,
                              ),
                            ),
                            child: Text(
                              AppFeatures.cloudSync
                                  ? 'Continue as Guest'
                                  : 'Get started',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        if (AppFeatures.cloudSync) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton(
                              onPressed: () => _finish(signIn: true),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: context.skin.primary,
                                side: BorderSide(color: context.skin.primary),
                                shape: RoundedRectangleBorder(
                                  borderRadius: context.skin.controlRadius,
                                ),
                              ),
                              child: const Text(
                                'Sign In / Sign Up',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ).animate().fadeIn()
                  : SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: () => _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: context.skin.primary,
                          foregroundColor: context.skin.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: context.skin.controlRadius,
                          ),
                        ),
                        child: const Text(
                          'Next',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final String emoji;
  final String title;
  final String body;
  const _Slide({required this.emoji, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final muted = skin.muted;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: skin.isFoodDelivery
                  ? skin.subtle
                  : skin.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 64)),
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 36),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: muted, height: 1.5),
          ),
        ],
      ),
    );
  }
}
