import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_skin.dart';
import '../../data/local/hive_service.dart';
import 'main_shell.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 900), _go);
  }

  void _go() {
    if (!mounted) return;
    final next = HiveService.onboarded ? const MainShell() : const OnboardingScreen();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => next,
        transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final fd = skin.isFoodDelivery;
    final fg = fd ? skin.text : Colors.white;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: fd ? Theme.of(context).scaffoldBackgroundColor : null,
          gradient: skin.heroGradient,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: fd ? skin.primary : Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(fd ? skin.radiusCard : 28),
                ),
                child: Center(
                  child: Text('₹',
                      style: TextStyle(
                          fontSize: 52,
                          fontWeight: fd ? FontWeight.w600 : FontWeight.w800,
                          color: fd ? skin.onPrimary : Colors.white)),
                ),
              ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 20),
              Text(
                'SpendCraft',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: fd ? FontWeight.w600 : FontWeight.w800,
                  color: fg,
                  letterSpacing: -0.5,
                ),
              ).animate().fadeIn(delay: 200.ms),
            ],
          ),
        ),
      ),
    );
  }
}
