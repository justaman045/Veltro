import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/settings_service.dart';

class AppearanceView extends ConsumerStatefulWidget {
  const AppearanceView({super.key});

  @override
  ConsumerState<AppearanceView> createState() => _AppearanceViewState();
}

class _AppearanceViewState extends ConsumerState<AppearanceView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Appearance', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Theme',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
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
                RadioListTile<ThemeMode>(
                  title: const Text('Light Theme', style: TextStyle(fontWeight: FontWeight.w500)),
                  value: ThemeMode.light,
                  // ignore: deprecated_member_use
                  groupValue: ref.watch(settingsServiceProvider).themeMode,
                  // ignore: deprecated_member_use
                  onChanged: (val) {
                    ref.read(settingsServiceProvider).setThemeMode(val!);
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
                RadioListTile<ThemeMode>(
                  title: const Text('Dark Theme', style: TextStyle(fontWeight: FontWeight.w500)),
                  value: ThemeMode.dark,
                  // ignore: deprecated_member_use
                  groupValue: ref.watch(settingsServiceProvider).themeMode,
                  // ignore: deprecated_member_use
                  onChanged: (val) {
                    ref.read(settingsServiceProvider).setThemeMode(val!);
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
                RadioListTile<ThemeMode>(
                  title: const Text('System Default', style: TextStyle(fontWeight: FontWeight.w500)),
                  value: ThemeMode.system,
                  // ignore: deprecated_member_use
                  groupValue: ref.watch(settingsServiceProvider).themeMode,
                  // ignore: deprecated_member_use
                  onChanged: (val) {
                    ref.read(settingsServiceProvider).setThemeMode(val!);
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
