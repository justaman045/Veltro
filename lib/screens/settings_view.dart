import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'account_profile_view.dart';
import 'notifications_view.dart';
import 'appearance_view.dart';
import 'about_view.dart';
import '../providers/providers.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
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
                  onTap: () {
                    Get.to(() => const AccountProfileView());
                  },
                ),
                const Divider(height: 1, indent: 60),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: const Icon(Icons.notifications_none),
                  title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w500)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    Get.to(() => const NotificationsView());
                  },
                ),
                const Divider(height: 1, indent: 60),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: const Icon(Icons.color_lens_outlined),
                  title: const Text('Appearance', style: TextStyle(fontWeight: FontWeight.w500)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    Get.to(() => const AppearanceView());
                  },
                ),
                const Divider(height: 1, indent: 60),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About Agentic Todo', style: TextStyle(fontWeight: FontWeight.w500)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    Get.to(() => const AboutView());
                  },
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

        ],
      ),
    );
  }
}
