import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/settings_service.dart';
import '../utils/app_colors.dart';

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
                SwitchListTile(
                  title: const Text('Push Notifications', style: TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: const Text('Master switch for all app notifications'),
                  value: ref.watch(settingsServiceProvider).notificationsEnabled,
                  onChanged: (val) {
                    ref.read(settingsServiceProvider).setNotificationsEnabled(val);
                  },
                  activeThumbColor: Theme.of(context).colorScheme.primary,
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
                SwitchListTile(
                  title: const Text('Task Reminders', style: TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: const Text('15-minute advance notice before tasks start'),
                  value: ref.watch(settingsServiceProvider).taskRemindersEnabled,
                  onChanged: (val) {
                    ref.read(settingsServiceProvider).setTaskRemindersEnabled(val);
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
