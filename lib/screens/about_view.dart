import 'package:flutter/material.dart';

class AboutView extends StatelessWidget {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('About', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20),
                ],
              ),
              child: Icon(Icons.check_circle_outline, size: 80, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 32),
            const Text(
              'Agentic Todo',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Version 1.0.0',
              style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'A premium local-first task management application built with Flutter and Riverpod, designed by Antigravity.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, height: 1.5, color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
