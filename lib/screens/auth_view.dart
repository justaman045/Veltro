import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import '../providers/providers.dart';

class AuthView extends ConsumerStatefulWidget {
  const AuthView({super.key});

  @override
  ConsumerState<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends ConsumerState<AuthView> {
  bool isLogin = true;
  bool isLoading = false;

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
      if (isLogin) {
        await auth.signInWithEmailPassword(email, password);
      } else {
        await auth.registerWithEmailPassword(email, password);
      }
    } catch (e) {
      Get.snackbar('Authentication Failed', e.toString().replaceAll('Exception: ', ''),
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
    } catch (e) {
      Get.snackbar('Authentication Failed', e.toString().replaceAll('Exception: ', ''),
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.hub_rounded, size: 80, color: Color(0xFF007AFF)),
                const SizedBox(height: 16),
                Text(
                  'Agentic Todo',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sync your tasks across devices.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 48),

                // Email Input
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 16),

                // Password Input
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 24),

                // Primary Button (Login/Register)
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : submitEmailAuth,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(
                            isLogin ? 'Sign In' : 'Create Account',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Toggle Login/Register
                TextButton(
                  onPressed: () => setState(() => isLogin = !isLogin),
                  child: Text(
                    isLogin ? 'Need an account? Sign Up' : 'Already have an account? Sign In',
                    style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
                ),
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(child: Divider(color: theme.colorScheme.onSurface.withValues(alpha: 0.2))),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('OR'),
                    ),
                    Expanded(child: Divider(color: theme.colorScheme.onSurface.withValues(alpha: 0.2))),
                  ],
                ),
                const SizedBox(height: 24),

                // Google Sign In Button
                SizedBox(
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: isLoading ? null : submitGoogleAuth,
                    icon: Image.network('https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/768px-Google_%22G%22_logo.svg.png', height: 24),
                    label: const Text('Continue with Google', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                      foregroundColor: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
