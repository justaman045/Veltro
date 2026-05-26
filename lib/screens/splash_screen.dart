import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_colors.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1, milliseconds: 200),
    )..forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: context.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // App icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Image.asset(
                    'assets/icon.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ).animate().fadeIn(
                duration: 600.ms,
                curve: Curves.easeOut,
              ).scale(
                begin: const Offset(0.85, 0.85),
                end: const Offset(1, 1),
                duration: 600.ms,
                curve: Curves.easeOutBack,
              ),
              const SizedBox(height: 32),
              // App title
              Text(
                'Agentic Todo',
                style: GoogleFonts.inter(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.0,
                  color: Colors.white,
                ),
              ).animate().fadeIn(
                duration: 500.ms,
                delay: 200.ms,
                curve: Curves.easeOut,
              ),
              const SizedBox(height: 8),
              // Tagline
              Text(
                'Your tasks, synced.',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.8),
                  letterSpacing: 0.2,
                ),
              ).animate().fadeIn(
                duration: 500.ms,
                delay: 400.ms,
                curve: Curves.easeOut,
              ),
              const Spacer(flex: 3),
              // Progress indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 80),
                child: AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, child) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: _progressController.value,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 3,
                      ),
                    );
                  },
                ),
              ).animate().fadeIn(
                duration: 400.ms,
                delay: 600.ms,
                curve: Curves.easeOut,
              ),
              const SizedBox(height: 16),
              // Loading text
              Text(
                'Setting things up\u2026',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ).animate().fadeIn(
                duration: 400.ms,
                delay: 700.ms,
                curve: Curves.easeOut,
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
