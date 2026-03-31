import 'package:flutter/material.dart';
import 'dart:ui';
import 'timeline_view.dart';
import 'todo_view.dart';
import '../widgets/task_entry_dialog.dart';
import 'package:get/get.dart';
import '../controllers/update_controller.dart';
import 'update_screen.dart';

class UnifiedScreen extends StatefulWidget {
  const UnifiedScreen({super.key});

  @override
  State<UnifiedScreen> createState() => _UnifiedScreenState();
}

class _UnifiedScreenState extends State<UnifiedScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    final updateInfo = await UpdateController.checkForUpdates();
    if (updateInfo != null && updateInfo.hasUpdate) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('New Update Available!'),
            content: Text('Agentic Todo version ${updateInfo.latestVersion} has been released on GitHub and is ready to download.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Later', style: TextStyle(color: Colors.grey)),
              ),
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
    }
  }

  final List<Widget> _views = const [
    TimelineView(),
    TodoView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      extendBody: true, // Allow content to scroll under frosted glass
      body: SafeArea(
        bottom: false,
        child: _views[_currentIndex],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const TaskEntryDialog(),
            );
          },
          backgroundColor: Theme.of(context).colorScheme.primary,
          elevation: 0,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white, size: 30),
        ),
      ),
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.75), // Translucent surface
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1), // Gentle dividing line
                  width: 0.5, // Hairline border
                ),
              ),
            ),
            child: SafeArea(
              child: NavigationBar(
                height: 64,
                elevation: 0,
                backgroundColor: Colors.transparent,
                selectedIndex: _currentIndex,
                onDestinationSelected: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                destinations: [
                  NavigationDestination(
                    icon: Icon(Icons.timeline_rounded, color: _currentIndex == 0 ? Theme.of(context).colorScheme.primary : Colors.grey),
                    label: 'Timeline',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.check_box_rounded, color: _currentIndex == 1 ? Theme.of(context).colorScheme.primary : Colors.grey),
                    label: 'Todos',
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
