import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../utils/app_colors.dart';

class AiBriefingCard extends ConsumerStatefulWidget {
  const AiBriefingCard({super.key});

  @override
  ConsumerState<AiBriefingCard> createState() => _AiBriefingCardState();
}

class _AiBriefingCardState extends ConsumerState<AiBriefingCard> {
  bool _expanded = true;
  bool _hasTrackedUsage = false;

  @override
  Widget build(BuildContext context) {
    final briefingAsync = ref.watch(dailyBriefingProvider);

    return briefingAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (briefing) {
        if (briefing.isEmpty) return const SizedBox.shrink();

        if (!_hasTrackedUsage) {
          _hasTrackedUsage = true;
          final isPro = ref.read(subscriptionServiceProvider).isPro;
          if (!isPro) {
            ref.read(aiUsageCountProvider.notifier).state++;
          }
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  context.gradientPrimary.withValues(alpha: 0.08),
                  context.gradientSecondary.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              border: Border.all(color: context.gradientPrimary.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: context.gradientPrimary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.auto_awesome, size: 16, color: context.gradientPrimary),
                    ),
                    const SizedBox(width: 10),
                    const Text('AI Briefing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const Spacer(),
                  ],
                ),
                if (_expanded) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      briefing,
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87, height: 1.4),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
