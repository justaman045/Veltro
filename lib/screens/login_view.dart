import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/providers.dart';
import '../utils/app_colors.dart';

class LoginView extends ConsumerStatefulWidget {
  final VoidCallback? onSignUp;

  const LoginView({super.key, this.onSignUp});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  bool isLoading = false;
  bool _obscurePassword = true;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> submitEmailAuth() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      Get.snackbar('Error', 'Please enter email and password',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    setState(() => isLoading = true);
    try {
      final auth = ref.read(authServiceProvider);
      await auth.signInWithEmailPassword(email, password).timeout(const Duration(seconds: 30));
      if (mounted) ref.invalidate(authStateProvider);
    } on FirebaseAuthException catch (e) {
      final message = _authErrorMessage(e.code);
      Get.snackbar('Sign In Failed', message,
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white);
    } on TimeoutException {
      Get.snackbar('Sign In Failed', 'Request timed out. Check your connection and try again.',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Sign In Failed', e.toString().replaceAll('Exception: ', ''),
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> submitGoogleAuth() async {
    setState(() => isLoading = true);
    try {
      final auth = ref.read(authServiceProvider);
      await auth.signInWithGoogle();
      // Force the StreamProvider to re-read Firebase's current state in case
      // the authStateChanges stream missed the sign-in event (Credential Manager race)
      if (mounted) ref.invalidate(authStateProvider);
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Sign In Failed'),
          content: Text(e.toString().replaceAll('Exception: ', '')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: context.richGradient),
        child: Stack(
          children: [
            Positioned(
              top: -100,
              right: -80,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Colors.white.withValues(alpha: 0.2), Colors.transparent],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              left: -100,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Colors.white.withValues(alpha: 0.14), Colors.transparent],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 240,
              left: -50,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Colors.white.withValues(alpha: 0.08), Colors.transparent],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.35),
                                Colors.white.withValues(alpha: 0.15),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 32,
                                offset: const Offset(0, 12),
                              ),
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.25),
                                blurRadius: 16,
                                spreadRadius: -4,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                              child: const Icon(
                                Icons.task_alt_rounded,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                          .scale(
                            begin: const Offset(0.75, 0.75),
                            end: const Offset(1, 1),
                            duration: 600.ms,
                            curve: Curves.easeOutBack,
                          ),

                      const SizedBox(height: 22),

                      Text(
                        'Agentic Todo',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.0,
                          color: Colors.white,
                        ),
                      ).animate().fadeIn(duration: 500.ms, delay: 150.ms),

                      const SizedBox(height: 6),

                      Text(
                        'Your tasks. Your way. Always in sync.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                      ).animate().fadeIn(duration: 500.ms, delay: 220.ms),

                      const SizedBox(height: 36),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  'Sign In',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 22),

                                _field(
                                  controller: emailController,
                                  label: 'Email',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                ),

                                const SizedBox(height: 12),

                                _field(
                                  controller: passwordController,
                                  label: 'Password',
                                  icon: Icons.lock_outline,
                                  obscureText: _obscurePassword,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: Colors.white.withValues(alpha: 0.55),
                                      size: 20,
                                    ),
                                    onPressed: () =>
                                        setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                ),

                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () async {
                                      final email = emailController.text.trim();
                                      if (email.isEmpty) {
                                        Get.snackbar('Email Required', 'Enter your email address first.',
                                            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.white.withValues(alpha: 0.9),
                                            colorText: Colors.black87);
                                        return;
                                      }
                                      try {
                                        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                                        Get.snackbar('Reset Link Sent', 'Check your email inbox.',
                                            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.white.withValues(alpha: 0.9),
                                            colorText: Colors.black87);
                                      } catch (e) {
                                        Get.snackbar('Reset Failed', e.toString().replaceAll('Exception: ', ''),
                                            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
                                            colorText: Colors.white);
                                      }
                                    },
                                    child: Text('Forgot Password?',
                                        style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                Container(
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: isLoading ? null : submitEmailAuth,
                                      child: Center(
                                        child: isLoading
                                            ? SizedBox(
                                                height: 22,
                                                width: 22,
                                                child: CircularProgressIndicator(
                                                  color: const Color(0xFF007AFF),
                                                  strokeWidth: 2.5,
                                                ),
                                              )
                                            : const Text(
                                                'Sign In',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF007AFF),
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                Row(
                                  children: [
                                    Expanded(
                                        child: Divider(color: Colors.white.withValues(alpha: 0.25))),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Text(
                                        'or',
                                        style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.5),
                                            fontSize: 13),
                                      ),
                                    ),
                                    Expanded(
                                        child: Divider(color: Colors.white.withValues(alpha: 0.25))),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                Container(
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.12),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: isLoading ? null : submitGoogleAuth,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Image.network(
                                            'https://www.gstatic.com/images/branding/product/2x/googleg_48dp.png',
                                            height: 20,
                                            errorBuilder: (context, error, stack) => const Icon(
                                              Icons.g_mobiledata,
                                              color: Colors.redAccent,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          const Text(
                                            'Continue with Google',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF3C3C3C),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 500.ms, delay: 320.ms, curve: Curves.easeOut)
                          .slideY(
                            begin: 0.07,
                            end: 0,
                            duration: 500.ms,
                            delay: 320.ms,
                            curve: Curves.easeOutCubic,
                          ),

                      const SizedBox(height: 24),

                      TextButton(
                        onPressed: widget.onSignUp,
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withValues(alpha: 0.8)),
                            children: [
                              TextSpan(text: "Don't have an account? "),
                              TextSpan(
                                text: 'Sign Up',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _authErrorMessage(String code) {
    switch (code) {
      case 'user-not-found': return 'No account found with this email.';
      case 'wrong-password': return 'Incorrect password. Try again.';
      case 'invalid-email': return 'Please enter a valid email address.';
      case 'user-disabled': return 'This account has been disabled.';
      case 'too-many-requests': return 'Too many attempts. Please try again later.';
      case 'invalid-credential': return 'Invalid email or password.';
      default: return code;
    }
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.6), size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
        ),
      ),
    );
  }
}
