import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'account_profile_view.dart';
import 'notifications_view.dart';
import 'appearance_view.dart';
import 'about_view.dart';
import 'stats_view.dart';
import 'templates_view.dart';
import 'pomodoro_view.dart';
import 'pricing_view.dart';
import 'ai_model_view.dart';
import '../providers/providers.dart';
import '../utils/app_colors.dart';
import '../utils/csv_export.dart';
import '../services/settings_service.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    final nav = Navigator.of(context, rootNavigator: true);
    showDialog<void>(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    bool dialogClosed = false;
    try {
      final tasks = await ref.read(dbServiceProvider).getAllTasks();
      final buf = StringBuffer();
      buf.writeln('Title,Notes,Category,Type,Priority,Recurrence,StartTime,EndTime,Completed');
      for (final t in tasks) {
        buf.writeln([
          csvEscape(t.title), csvEscape(t.notes), t.category.name, t.type.name,
          t.priority.name, t.recurrence.name,
          t.startTime?.toIso8601String() ?? '',
          t.endTime?.toIso8601String() ?? '',
          t.isCompleted.toString(),
        ].join(','));
      }
      final bytes = Uint8List.fromList(utf8.encode(buf.toString()));
      if (!context.mounted) return;
      nav.pop();
      dialogClosed = true;
      final result = await FilePicker.platform.saveFile(fileName: 'agentic_todo_export.csv', bytes: bytes);
      if (result != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exported to: $result'), duration: const Duration(seconds: 3)));
      }
    } catch (e) {
      if (!context.mounted) return;
      if (!dialogClosed) nav.pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Widget _buildProGate(WidgetRef ref, Widget child) {
    final isPro = ref.watch(isProProvider).valueOrNull ?? false;
    if (isPro) return child;
    return GestureDetector(
      onTap: () => Get.to(() => const PricingView()),
      child: Stack(
        children: [
          AbsorbPointer(child: Opacity(opacity: 0.4, child: child)),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_rounded, size: 14, color: Colors.white),
                      SizedBox(width: 6),
                      Text('Pro Feature', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(isProProvider).valueOrNull ?? false;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Subscription card
          GestureDetector(
            onTap: () => Get.to(() => const PricingView()),
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: isPro
                    ? LinearGradient(colors: [context.gradientPrimary.withValues(alpha: 0.1), context.gradientSecondary.withValues(alpha: 0.1)])
                    : context.primaryGradient,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isPro ? context.gradientPrimary.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isPro ? Icons.verified_rounded : Icons.star_border_rounded,
                      color: isPro ? context.gradientPrimary : Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPro ? 'You\'re on Pro' : 'Upgrade to Pro',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isPro ? Theme.of(context).colorScheme.onSurface : Colors.white,
                          ),
                        ),
                        Text(
                          isPro ? 'All premium features unlocked' : 'Unlock AI, templates, stats & more',
                          style: TextStyle(
                            fontSize: 13,
                            color: isPro ? Colors.grey.shade500 : Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: isPro ? Colors.grey : Colors.white),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: context.subtleGradient,
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05),
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.1 : 0.05),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Account Profile', style: TextStyle(fontWeight: FontWeight.w500)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () => Get.to(() => const AccountProfileView()),
                ),
                const Divider(height: 1, indent: 60),
                _buildProGate(ref, ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: const Icon(Icons.bar_chart_rounded),
                  title: const Text('Productivity Stats', style: TextStyle(fontWeight: FontWeight.w500)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () => Get.to(() => const StatsView()),
                )),
                const Divider(height: 1, indent: 60),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: const Icon(Icons.timer_rounded),
                  title: const Text('Pomodoro Timer', style: TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: const Text('Focus sessions for any task', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () => Get.to(() => const PomodoroView(taskTitle: 'Focus Session')),
                ),
                const Divider(height: 1, indent: 60),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: const Icon(Icons.auto_awesome_rounded),
                  title: const Text('AI Model', style: TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Consumer(
                    builder: (context, ref, _) {
                      final model = ref.watch(settingsServiceProvider.select((s) => s.openRouterModel));
                      final short = model.length > 30 ? '${model.substring(0, 28)}…' : model;
                      return Text(short, style: const TextStyle(fontSize: 12));
                    },
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () => Get.to(() => const AiModelView()),
                ),
                const Divider(height: 1, indent: 60),
                _buildProGate(ref, ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: const Icon(Icons.content_copy_rounded),
                  title: const Text('Task Templates', style: TextStyle(fontWeight: FontWeight.w500)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () => Get.to(() => const TemplatesView()),
                )),
                const Divider(height: 1, indent: 60),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: const Icon(Icons.notifications_none),
                  title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w500)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () => Get.to(() => const NotificationsView()),
                ),
                const Divider(height: 1, indent: 60),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: const Icon(Icons.color_lens_outlined),
                  title: const Text('Appearance', style: TextStyle(fontWeight: FontWeight.w500)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () => Get.to(() => const AppearanceView()),
                ),
                const Divider(height: 1, indent: 60),
                _buildProGate(ref, ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: const Icon(Icons.download_rounded),
                  title: const Text('Export Tasks as CSV', style: TextStyle(fontWeight: FontWeight.w500)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () => _exportCsv(context, ref),
                )),
                const Divider(height: 1, indent: 60),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About Agentic Todo', style: TextStyle(fontWeight: FontWeight.w500)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () => Get.to(() => const AboutView()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          TextButton(
            onPressed: () async {
              final confirm = await Get.dialog<bool>(
                AlertDialog(
                  title: const Text('Clear All Data?'),
                  content: const Text('This will permanently delete all tasks. This cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Get.back(result: true),
                      child: const Text('Delete All', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                final db = ref.read(dbServiceProvider);
                await db.clearAllData();
                Get.snackbar('Data Cleared', 'All tasks have been deleted.');
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
            ),
            child: const Text('Clear All Data', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: context.primaryGradient,
            ),
            child: TextButton(
              onPressed: () async {
                final confirm = await Get.dialog<bool>(
                  AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Get.back(result: true),
                        child: const Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref.read(authServiceProvider).signOut();
                  if (!context.mounted) return;
                  Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Sign Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
