import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/time_task.dart';
import '../providers/providers.dart';
import '../utils/app_colors.dart';

class AiTaskBreakdownSheet extends ConsumerStatefulWidget {
  const AiTaskBreakdownSheet({super.key});

  @override
  ConsumerState<AiTaskBreakdownSheet> createState() => _AiTaskBreakdownSheetState();
}

class _AiTaskBreakdownSheetState extends ConsumerState<AiTaskBreakdownSheet> {
  final _goalController = TextEditingController();
  bool _loading = false;
  List<TimeTask> _generatedTasks = [];
  Set<int> _selectedIndices = {};

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _breakdown() async {
    final goal = _goalController.text.trim();
    if (goal.isEmpty) return;

    final isPro = ref.read(subscriptionServiceProvider).isPro;
    final aiUsage = ref.read(aiUsageCountProvider.notifier).state;
    if (!isPro && aiUsage >= 3) {
      Get.snackbar('AI Limit Reached', 'Upgrade to Pro for unlimited AI actions.',
          snackPosition: SnackPosition.TOP, backgroundColor: Colors.black87,
          colorText: Colors.white, margin: const EdgeInsets.all(16),
          borderRadius: 12, duration: const Duration(seconds: 3));
      return;
    }

    setState(() => _loading = true);
    try {
      final tasks = await ref.read(aiServiceProvider).breakdownTask(goal);
      if (!mounted) return;
      setState(() {
        _generatedTasks = tasks;
        _selectedIndices = {for (int i = 0; i < tasks.length; i++) i};
        _loading = false;
      });
      if (!isPro) {
        ref.read(aiUsageCountProvider.notifier).state++;
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        Get.snackbar('Error', e.toString().replaceAll('Exception: ', ''),
            snackPosition: SnackPosition.TOP, backgroundColor: Colors.redAccent,
            colorText: Colors.white, margin: const EdgeInsets.all(16),
            borderRadius: 12, duration: const Duration(seconds: 3));
      }
    }
  }

  Future<void> _saveSelected() async {
    final db = ref.read(dbServiceProvider);
    final selected = _selectedIndices.map((i) => _generatedTasks[i]).toList();
    for (final task in selected) {
      await db.saveTimeTask(task);
    }
    if (mounted) {
      Navigator.of(context).pop();
      Get.snackbar('Tasks Created', '${selected.length} tasks added to your timeline.',
          snackPosition: SnackPosition.TOP, backgroundColor: Colors.black87,
          colorText: Colors.white, margin: const EdgeInsets.all(16),
          borderRadius: 12, duration: const Duration(seconds: 3));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: bottomInset + 32),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('AI Task Breakdown', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                IconButton(
                  icon: const Icon(Icons.close, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Describe a goal and AI will break it into actionable tasks.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _goalController,
                      autofocus: true,
                      style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText: 'E.g. "Plan a weekend trip to Mumbai"',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black26),
                      ),
                      onSubmitted: (_) => _breakdown(),
                    ),
                  ),
                  GestureDetector(
                    onTap: _loading ? null : _breakdown,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: context.gradientPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _loading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(Icons.auto_awesome, color: context.gradientPrimary, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            if (_generatedTasks.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${_generatedTasks.length} tasks generated',
                      style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade500, fontSize: 13)),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => setState(() {
                          _selectedIndices = {for (int i = 0; i < _generatedTasks.length; i++) i};
                        }),
                        child: const Text('Select All', style: TextStyle(fontSize: 13)),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => setState(() => _selectedIndices.clear()),
                        child: const Text('Clear', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._generatedTasks.asMap().entries.map((entry) {
                final i = entry.key;
                final task = entry.value;
                final isSelected = _selectedIndices.contains(i);
                final catColor = TimeTask.categoryColors[task.category] ?? Colors.grey;

                return GestureDetector(
                  onTap: () => setState(() {
                    if (isSelected) {
                      _selectedIndices.remove(i);
                    } else {
                      _selectedIndices.add(i);
                    }
                  }),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? catColor.withValues(alpha: 0.5) : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          size: 22,
                          color: isSelected ? catColor : Colors.grey.shade400,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(task.title, style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface,
                              )),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: catColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      task.category.name.capitalizeFirst ?? task.category.name,
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: catColor),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: catColor.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      task.priority.name.capitalizeFirst ?? task.priority.name,
                                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: context.primaryGradient,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _selectedIndices.isEmpty ? null : _saveSelected,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Center(
                        child: Text(
                          'Add ${_selectedIndices.length} Selected Tasks',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _selectedIndices.isEmpty ? Colors.white54 : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
