import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../utils/app_colors.dart';

final _versionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version}+${info.buildNumber}';
});

class AboutView extends ConsumerWidget {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionString = ref.watch(_versionProvider).valueOrNull ?? '...';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: context.gradientPrimary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(gradient: context.richGradient),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 24, offset: const Offset(0, 8)),
                          ],
                        ),
                        child: const Icon(Icons.check_circle_outline_rounded, size: 68, color: Colors.white),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Agentic Todo',
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'Version $versionString',
                          style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Description card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    gradient: context.subtleGradient,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
                  ),
                  child: Text(
                    'A premium task management app built with Flutter and Firebase, featuring smart scheduling, habit streaks, and Pomodoro focus sessions.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, height: 1.65, color: Theme.of(context).colorScheme.onSurface),
                  ),
                ),
                const SizedBox(height: 28),

                // Features
                Text('Features', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 12),
                _FeatureCard(
                  icon: Icons.timeline_rounded,
                  color: const Color(0xFF007AFF),
                  title: 'Smart Timeline',
                  description: 'Schedule tasks across a scrollable daily timeline with drag-and-drop reordering.',
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _FeatureCard(
                  icon: Icons.local_fire_department_rounded,
                  color: const Color(0xFFFF9500),
                  title: 'Habit Streaks',
                  description: 'Build consistency with recurring daily, weekly, or monthly tasks and streak tracking.',
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _FeatureCard(
                  icon: Icons.timer_rounded,
                  color: const Color(0xFFFF3B30),
                  title: 'Pomodoro Timer',
                  description: '25-minute focus sessions with break reminders. Tap the timer icon on any timeline task.',
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _FeatureCard(
                  icon: Icons.calendar_month_rounded,
                  color: const Color(0xFF34C759),
                  title: 'Calendar View',
                  description: 'See all tasks across months with color-coded category dots and one-tap navigation.',
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _FeatureCard(
                  icon: Icons.content_copy_rounded,
                  color: const Color(0xFFAF52DE),
                  title: 'Task Templates',
                  description: 'Save frequently used tasks and reuse them instantly. Long-press the + button to open templates.',
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _FeatureCard(
                  icon: Icons.cloud_sync_rounded,
                  color: const Color(0xFF5E5CE6),
                  title: 'Firebase Sync',
                  description: 'All tasks sync securely across devices in real time via Firestore.',
                  isDark: isDark,
                ),
                const SizedBox(height: 28),

                // Built with
                Text('Built With', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _TechPill(label: 'Flutter', icon: Icons.flutter_dash, color: const Color(0xFF027DFD)),
                      _TechPill(label: 'Firebase', icon: Icons.local_fire_department_rounded, color: const Color(0xFFFF9500)),
                      _TechPill(label: 'Riverpod', icon: Icons.hub_rounded, color: const Color(0xFF5E5CE6)),
                      _TechPill(label: 'GetX', icon: Icons.speed_rounded, color: const Color(0xFF34C759)),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.favorite_rounded, size: 18, color: Colors.redAccent.withValues(alpha: 0.7)),
                      const SizedBox(height: 6),
                      Text(
                        'Made with love by Antigravity',
                        style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final bool isDark;

  const _FeatureCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 23),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(description, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TechPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _TechPill({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 22, color: color),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
      ],
    );
  }
}
