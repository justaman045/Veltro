import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../utils/app_colors.dart';

class PricingView extends ConsumerWidget {
  const PricingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tier = ref.watch(tierProvider).valueOrNull ?? 'free';
    final isPro = tier == 'pro' || tier == 'proMax';
    final isProMax = tier == 'proMax';

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Subscriptions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildStatusCard(context, tier, isPro, isProMax),
            const SizedBox(height: 32),
            _buildFeatureComparison(context, isPro, isProMax),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, String tier, bool isPro, bool isProMax) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            context.gradientPrimary.withValues(alpha: 0.15),
            context.gradientSecondary.withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        border: Border.all(color: context.gradientPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            isProMax ? Icons.workspace_premium_rounded : isPro ? Icons.verified_rounded : Icons.person_outline_rounded,
            size: 64,
            color: isProMax ? Colors.amber : context.gradientPrimary,
          ),
          const SizedBox(height: 16),
          Text(
            isProMax ? 'Pro Max' : isPro ? 'Pro' : 'Free',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            isProMax ? 'All premium features unlocked' : isPro ? 'Premium features unlocked' : 'Basic plan',
            style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.withValues(alpha: 0.1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.admin_panel_settings_outlined, size: 18, color: Colors.grey.shade500),
                const SizedBox(width: 8),
                Text(
                  'Managed by your account admin',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureComparison(BuildContext context, bool isPro, bool isProMax) {
    final features = [
      ('Task CRUD', 'Create, edit, delete tasks', true, true, true),
      ('Timeline & Calendar', 'Daily timeline with drag-drop', true, true, true),
      ('Pomodoro Timer', 'Focus sessions', true, true, true),
      ('NLP Date Parsing', 'Natural language time detection', true, true, true),
      ('AI Task Parsing', 'Smart task details extraction', true, true, true),
      ('AI Task Breakdown', 'Goal breakdown into subtasks', true, true, true),
      ('Daily AI Briefing', 'AI-generated daily summary', true, true, true),
      ('Task Templates', 'Save and reuse templates', false, true, true),
      ('Productivity Stats', 'Charts, streaks, analytics', false, true, true),
      ('CSV Export', 'Export tasks to CSV', false, true, true),
      ('Premium Themes', 'Exclusive visual themes', false, false, true),
      ('Priority Support', 'Faster help & support', false, false, true),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Feature Comparison', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...features.map((f) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(
                _checkState(f.$3, f.$4, f.$5, isPro, isProMax) ? Icons.check_circle_rounded : Icons.cancel_outlined,
                size: 20,
                color: _checkState(f.$3, f.$4, f.$5, isPro, isProMax)
                    ? Colors.green : Colors.grey.shade400,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(f.$1, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ),
              _tierIcon(f.$3, f.$4, f.$5),
            ],
          ),
        )),
      ],
    );
  }

  bool _checkState(bool free, bool pro, bool proMax, bool isPro, bool isProMax) {
    if (isProMax && proMax) return true;
    if (isPro && pro) return true;
    if (free) return true;
    return false;
  }

  Widget _tierIcon(bool free, bool pro, bool proMax) {
    if (proMax) return Icon(Icons.workspace_premium_rounded, size: 16, color: Colors.amber);
    if (pro) return Icon(Icons.verified_rounded, size: 16, color: Colors.blue);
    return const Icon(Icons.person_outline, size: 16, color: Colors.grey);
  }
}
