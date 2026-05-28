import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'timeline_view.dart';
import 'todo_view.dart';
import 'calendar_view.dart';
import '../widgets/task_entry_dialog.dart';
import '../widgets/ai_task_breakdown_sheet.dart';
import 'templates_view.dart';
import 'pricing_view.dart';
import 'package:get/get.dart';
import '../controllers/update_controller.dart';
import 'update_screen.dart';
import '../utils/app_colors.dart';
import '../utils/animations.dart';
import '../services/notification_service.dart';
import '../providers/providers.dart';

class UnifiedScreen extends ConsumerStatefulWidget {
  const UnifiedScreen({super.key});

  @override
  ConsumerState<UnifiedScreen> createState() => _UnifiedScreenState();
}

class _UnifiedScreenState extends ConsumerState<UnifiedScreen> {
  int _currentIndex = 0;
  double _fabScale = 1.0;

  @override
  void initState() {
    super.initState();
    _views = [
      const TimelineView(),
      const TodoView(),
      CalendarView(onSwitchToTimeline: () => setState(() => _currentIndex = 0)),
    ];
    _checkForUpdates();
    _requestNotificationPermissions();
  }

  Future<void> _requestNotificationPermissions() async {
    try {
      await NotificationService().requestPermissions();
    } catch (_) {}
  }

  Future<void> _checkForUpdates() async {
    try {
      final updateInfo = await UpdateController.checkForUpdates();
      if (updateInfo != null && updateInfo.hasUpdate && mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('New Update Available!'),
            content: Text('Agentic Todo version ${updateInfo.latestVersion} has been released on GitHub and is ready to download.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Later', style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  Get.to(() => UpdateScreen(updateInfo: updateInfo), transition: Transition.downToUp);
                },
                child: const Text('View Update'),
              ),
            ],
          ),
        );
      }
    } catch (_) {}
  }

  late final List<Widget> _views;

  void _openNewTask() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TaskEntryDialog(),
    );
  }

  void _openAiBreakdown() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AiTaskBreakdownSheet(),
    );
  }

  void _openTemplates() {
    final isPro = ref.read(subscriptionServiceProvider).isPro;
    if (isPro) {
      Get.to(() => const TemplatesView());
    } else {
      Get.to(() => const PricingView());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: AnimatedSwitcher(
          duration: animDuration(context, ms: 300),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.03, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: KeyedSubtree(key: ValueKey(_currentIndex), child: _views[_currentIndex]),
        ),
      ),
      floatingActionButton: GestureDetector(
        onTapDown: (_) => setState(() => _fabScale = 0.92),
        onTapUp: (_) {
          if (mounted) setState(() => _fabScale = 1.0);
        },
        onTapCancel: () {
          if (mounted) setState(() => _fabScale = 1.0);
        },
        onLongPress: () {
          Get.bottomSheet(
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    alignment: Alignment.center,
                  ),
                  Text('Quick Actions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: context.gradientPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.auto_awesome, color: context.gradientPrimary),
                    ),
                    title: const Text('AI Task Breakdown', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Break a goal into tasks', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Get.back();
                      _openAiBreakdown();
                    },
                  ),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: context.gradientSecondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.content_copy_rounded, color: context.gradientSecondary),
                    ),
                    title: const Text('Templates', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Reuse saved task templates', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Get.back();
                      _openTemplates();
                    },
                  ),
                ],
              ),
            ),
          );
        },
        child: AnimatedScale(
          scale: _fabScale,
          duration: kAnimFast,
          curve: Curves.easeInOut,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: context.primaryGradient,
              boxShadow: [
                BoxShadow(color: context.gradientPrimary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8)),
              ],
            ),
            child: FloatingActionButton(
              onPressed: _openNewTask,
              backgroundColor: Colors.transparent,
              elevation: 0,
              shape: const CircleBorder(),
              tooltip: 'Hold for more options',
              child: const Icon(Icons.add, color: Colors.white, size: 30),
            ),
          ),
        ),
      ),
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.75),
              border: Border(top: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1), width: 0.5)),
            ),
            child: SafeArea(
              child: NavigationBar(
                height: 64,
                elevation: 0,
                backgroundColor: Colors.transparent,
                selectedIndex: _currentIndex,
                onDestinationSelected: (index) => setState(() => _currentIndex = index),
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.timeline_rounded),
                    selectedIcon: Icon(Icons.timeline_rounded, color: Theme.of(context).colorScheme.primary),
                    label: 'Timeline',
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.check_box_rounded),
                    selectedIcon: Icon(Icons.check_box_rounded, color: Theme.of(context).colorScheme.primary),
                    label: 'Todos',
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.calendar_month_rounded),
                    selectedIcon: Icon(Icons.calendar_month_rounded, color: Theme.of(context).colorScheme.primary),
                    label: 'Calendar',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
