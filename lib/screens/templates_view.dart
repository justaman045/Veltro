import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/time_task.dart';
import '../providers/providers.dart';
import '../widgets/task_entry_dialog.dart';
import '../utils/app_colors.dart';

class TemplatesView extends ConsumerWidget {
  const TemplatesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(templateTasksProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Templates', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: templatesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (templates) {
          if (templates.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: context.gradientPrimary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.content_copy_rounded, size: 56, color: context.gradientPrimary.withValues(alpha: 0.5)),
                  ),
                  const SizedBox(height: 20),
                  Text('No templates yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Save any task as a template from the task editor to reuse it quickly.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              final accentColor = TimeTask.categoryColors[template.category] ?? TimeTask.categoryColors[TaskCategory.other]!;
              final isDark = Theme.of(context).brightness == Brightness.dark;

              return Dismissible(
                key: Key('tmpl_${template.id}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                confirmDismiss: (_) async {
                  final confirm = await Get.dialog<bool>(AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: const Text('Delete Template?'),
                    content: Text('Remove "${template.title}" template permanently?'),
                    actions: [
                      TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Get.back(result: true), child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
                    ],
                  ));
                  if (confirm == true) {
                    await ref.read(dbServiceProvider).deleteTemplate(template.id);
                    return true;
                  }
                  return false;
                },
                child: GestureDetector(
                  onTap: () {
                    // Create a new task from this template (no ID so it creates a new task)
                    final newTask = TimeTask()
                      ..title = template.title
                      ..notes = template.notes
                      ..type = template.type
                      ..category = template.category
                      ..recurrence = template.recurrence
                      ..priority = template.priority
                      ..subtasks = template.subtasks?.map((s) => Map<String, dynamic>.from(s)..['done'] = false).toList();
                    Get.back();
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => TaskEntryDialog(existingTask: newTask, isFromTemplate: true),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accentColor.withValues(alpha: 0.2)),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.content_copy_rounded, color: accentColor, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(template.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      template.category.name[0].toUpperCase() + template.category.name.substring(1),
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accentColor),
                                    ),
                                  ),
                                  if (template.recurrence != RecurrenceType.none) ...[
                                    const SizedBox(width: 6),
                                    Icon(Icons.repeat, size: 12, color: Colors.grey.shade400),
                                    const SizedBox(width: 2),
                                    Text(template.recurrence.name, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                                  ],
                                  if (template.startTime != null) ...[
                                    const SizedBox(width: 6),
                                    Icon(Icons.access_time, size: 12, color: Colors.grey.shade400),
                                    const SizedBox(width: 2),
                                    Text(DateFormat.jm().format(template.startTime!), style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                final confirm = await Get.dialog<bool>(AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  title: const Text('Delete Template?'),
                                  content: Text('Remove "${template.title}" template permanently?'),
                                  actions: [
                                    TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
                                    TextButton(onPressed: () => Get.back(result: true), child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
                                  ],
                                ));
                                if (confirm == true) {
                                  await ref.read(dbServiceProvider).deleteTemplate(template.id);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.chevron_right, color: Colors.grey.shade400),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
