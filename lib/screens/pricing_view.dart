import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../providers/providers.dart';
import '../utils/app_colors.dart';

class PricingView extends ConsumerWidget {
  const PricingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(isProProvider).valueOrNull ?? false;
    final offeringsAsync = ref.watch(offeringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Upgrade to Pro', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (isPro) ...[
              Container(
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
                    Icon(Icons.verified_rounded, size: 64, color: context.gradientPrimary),
                    const SizedBox(height: 16),
                    const Text('You\'re on Pro', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Enjoy all premium features.', style: TextStyle(fontSize: 15, color: Colors.grey.shade500)),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                  onPressed: () async {
                        await ref.read(subscriptionServiceProvider).restorePurchases();
                        Get.snackbar('Restored', 'Purchases restored successfully.',
                            snackPosition: SnackPosition.TOP, backgroundColor: Colors.black87,
                            colorText: Colors.white, margin: const EdgeInsets.all(16),
                            borderRadius: 12, duration: const Duration(seconds: 2));
                      },
                      icon: const Icon(Icons.restore_rounded),
                      label: const Text('Restore Purchases'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              _buildFeatureList(context),
              const SizedBox(height: 32),
              offeringsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Column(
                  children: [
                    Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text('Could not load pricing', style: TextStyle(color: Colors.grey.shade500)),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ref.invalidate(offeringsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
                data: (offerings) {
                  if (offerings == null || offerings.current == null) {
                    return Column(
                      children: [
                        Icon(Icons.info_outline, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text('No products available yet.\nConfigure products in RevenueCat dashboard.',
                            textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                      ],
                    );
                  }
                  final current = offerings.current!;
                  return Column(
                    children: current.availablePackages.map((pkg) {
                      return _buildPackageCard(context, ref, pkg, isDark);
                    }).toList(),
                  );
                },
              ),
            ],
            const SizedBox(height: 32),
            TextButton(
              onPressed: () async {
                await ref.read(subscriptionServiceProvider).restorePurchases();
                Get.snackbar('Restored', 'Purchases restored.',
                    snackPosition: SnackPosition.TOP, backgroundColor: Colors.black87,
                    colorText: Colors.white, margin: const EdgeInsets.all(16),
                    borderRadius: 12, duration: const Duration(seconds: 2));
              },
              child: Text('Restore Purchases', style: TextStyle(color: Colors.grey.shade500)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureList(BuildContext context) {
    final features = [
      ('Unlimited Tasks', 'No task count limits', Icons.all_inclusive_rounded),
      ('Task Templates', 'Save and reuse task templates', Icons.content_copy_rounded),
      ('Productivity Stats', 'Detailed analytics and insights', Icons.bar_chart_rounded),
      ('CSV Export', 'Export tasks to CSV', Icons.download_rounded),
      ('Unlimited AI Actions', 'AI task breakdown, briefing, and more', Icons.auto_awesome_rounded),
      ('Priority Support', 'Get help faster', Icons.support_agent_rounded),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pro Features', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Get the most out of Agentic Todo', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
        const SizedBox(height: 20),
        ...features.map((f) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.gradientPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(f.$3, size: 20, color: context.gradientPrimary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.$1, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    Text(f.$2, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildPackageCard(BuildContext context, WidgetRef ref, Package pkg, bool isDark) {
    final isMonthly = pkg.packageType == PackageType.monthly;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: isMonthly ? LinearGradient(
          colors: [context.gradientPrimary.withValues(alpha: 0.08), context.gradientSecondary.withValues(alpha: 0.08)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ) : null,
        color: isMonthly ? null : (isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade50),
        border: Border.all(color: isMonthly
            ? context.gradientPrimary.withValues(alpha: 0.3)
            : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isMonthly ? 'Monthly' : 'Annual',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (!isMonthly)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.gradientPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('BEST VALUE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.gradientPrimary)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(pkg.storeProduct.priceString, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          if (!isMonthly)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${pkg.storeProduct.priceString}/month',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: context.primaryGradient,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    try {
                      await ref.read(subscriptionServiceProvider).purchasePackage(pkg);
                      if (context.mounted) {
                        Get.back();
                        Get.snackbar('Welcome to Pro!', 'All premium features are now unlocked.',
                            snackPosition: SnackPosition.TOP, backgroundColor: Colors.black87,
                            colorText: Colors.white, margin: const EdgeInsets.all(16),
                            borderRadius: 12, duration: const Duration(seconds: 3));
                      }
                    } catch (e) {
                      if (context.mounted) {
                        Get.snackbar('Purchase Failed', e.toString().replaceAll('Exception: ', ''),
                            snackPosition: SnackPosition.TOP, backgroundColor: Colors.redAccent,
                            colorText: Colors.white, margin: const EdgeInsets.all(16),
                            borderRadius: 12, duration: const Duration(seconds: 3));
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text('Subscribe', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
