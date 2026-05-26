import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../services/settings_service.dart';

class AiModelView extends ConsumerWidget {
  const AiModelView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelsAsync = ref.watch(openRouterModelsProvider);
    final currentModel = ref.watch(settingsServiceProvider.select((s) => s.openRouterModel));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Select AI Model', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: modelsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text('Could not load models', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                const SizedBox(height: 8),
                Text('Check your internet connection and try again.', style: TextStyle(color: Colors.grey.shade500)),
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: () => ref.invalidate(openRouterModelsProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (models) {
          if (models.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No models available', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          final free = models.where((m) => m['isFree'] == true).toList();
          final paid = models.where((m) => m['isFree'] != true).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (free.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text('FREE MODELS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500, letterSpacing: 1)),
                ),
                ...free.map((m) => _ModelTile(model: m, isSelected: m['id'] == currentModel, ref: ref)),
                const SizedBox(height: 24),
              ],
              if (paid.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text('PAID MODELS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500, letterSpacing: 1)),
                ),
                ...paid.map((m) => _ModelTile(model: m, isSelected: m['id'] == currentModel, ref: ref)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ModelTile extends StatelessWidget {
  final Map<String, dynamic> model;
  final bool isSelected;
  final WidgetRef ref;

  const _ModelTile({required this.model, required this.isSelected, required this.ref});

  @override
  Widget build(BuildContext context) {
    final id = model['id'] as String? ?? '';
    final name = model['name'] as String? ?? id;
    final isFree = model['isFree'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
            : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1C1C1E) : Colors.white),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)
              : (Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            if (!isSelected) {
              ref.read(settingsServiceProvider).setOpenRouterModel(id);
              ref.read(aiServiceProvider).setModel(id);
              Get.snackbar(
                'Model Updated',
                'Switched to $name',
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.black87,
                colorText: Colors.white,
                margin: const EdgeInsets.all(16),
                borderRadius: 12,
                duration: const Duration(seconds: 2),
                icon: const Icon(Icons.check_circle, color: Colors.greenAccent),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                          ),
                          if (isFree)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('Free', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.green.shade700)),
                            ),
                          if (isSelected)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Icon(Icons.check_circle, size: 20, color: Theme.of(context).colorScheme.primary),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(id, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
