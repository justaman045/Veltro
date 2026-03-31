import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/settings_service.dart';
import '../providers/providers.dart';
class NotificationsView extends ConsumerWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
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
                SwitchListTile(
                  title: const Text('Push Notifications', style: TextStyle(fontWeight: FontWeight.w500)),
                  value: ref.watch(settingsServiceProvider).notificationsEnabled,
                  onChanged: (val) {
                    ref.read(settingsServiceProvider).setNotificationsEnabled(val);
                  },
                  activeThumbColor: Theme.of(context).colorScheme.primary,
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
                SwitchListTile(
                  title: const Text('Email Notifications', style: TextStyle(fontWeight: FontWeight.w500)),
                  value: ref.watch(userProfileDataProvider).value?['emailNotificationsEnabled'] == true,
                  onChanged: (val) async {
                    final user = ref.read(authServiceProvider).currentUser;
                    if (user != null && user.email != null) {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.email)
                          .set({'emailNotificationsEnabled': val}, SetOptions(merge: true));
                      ref.invalidate(userProfileDataProvider);
                    }
                  },
                  activeThumbColor: Theme.of(context).colorScheme.primary,
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
                SwitchListTile(
                  title: const Text('Task Reminders', style: TextStyle(fontWeight: FontWeight.w500)),
                  value: true,
                  onChanged: (val) {
                    // Future roadmap
                  },
                  activeThumbColor: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
