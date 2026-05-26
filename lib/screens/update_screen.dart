import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/update_controller.dart';
import '../utils/app_colors.dart';

class UpdateScreen extends StatelessWidget {
  final UpdateInfo updateInfo;

  const UpdateScreen({super.key, required this.updateInfo});

  Future<void> _launchUpdateUrl(BuildContext context) async {
    final Uri url = Uri.parse(updateInfo.downloadUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not automatically launch the browser. Please check your GitHub permissions.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Agentic Todo Updates'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: context.subtleGradient,
                ),
                child: Center(
                  child: Icon(
                    Icons.system_update_rounded,
                    size: 64,
                    color: context.gradientPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Semantic version string alerts
              Text(
                'A new version is here!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(height: 12),
              Text(
                'Version ${updateInfo.latestVersion} is now available to download. Your hardware is currently running version ${updateInfo.currentVersion}.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),
              
              // Changelog Box Layout Target
              Text(
                'What\'s New',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      updateInfo.changelog,
                      style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8), height: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: context.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: context.gradientPrimary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => _launchUpdateUrl(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('Download App', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              
              // Fallback
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Remind me later', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
