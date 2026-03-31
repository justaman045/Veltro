import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/time_task.dart';
import '../providers/providers.dart';
import '../widgets/task_entry_dialog.dart';
import 'settings_view.dart';

class TodoView extends ConsumerStatefulWidget {
  const TodoView({super.key});

  @override
  ConsumerState<TodoView> createState() => _TodoViewState();
}

class _TodoViewState extends ConsumerState<TodoView> {
  final TextEditingController _searchController = TextEditingController();
  TaskCategory? _selectedCategoryFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todosAsync = ref.watch(todoTasksProvider);

    return todosAsync.when(
      data: (tasks) {
        final totalOpenTasks = tasks.where((t) => !t.isCompleted).toList();
        var openTasks = totalOpenTasks;
        
        final query = _searchController.text.toLowerCase();
        if (query.isNotEmpty) {
          openTasks = openTasks.where((t) => 
            t.title.toLowerCase().contains(query) || 
            t.notes.toLowerCase().contains(query)
          ).toList();
        }
        
        if (_selectedCategoryFilter != null) {
          openTasks = openTasks.where((t) => t.category == _selectedCategoryFilter).toList();
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Premium Header area
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Tasks',
                        style: TextStyle(
                          fontSize: 34, // Large iOS Header
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.0,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${openTasks.length} tasks pending',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.primary, // Professional Accent
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Get.to(() => const SettingsView());
                    },
                    child: const CircleAvatar(
                      radius: 18,
                      backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
            
            // Search Bar Mockup
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16), // Soft iOS Corners
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() {}),
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Search',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    PopupMenuButton<dynamic>(
                      initialValue: _selectedCategoryFilter,
                      onSelected: (value) {
                        setState(() { 
                          if (value == 'clear') {
                            _selectedCategoryFilter = null;
                          } else if (value is TaskCategory) {
                            _selectedCategoryFilter = value;
                          }
                        });
                      },
                      color: Theme.of(context).cardTheme.color,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _selectedCategoryFilter != null 
                              ? Theme.of(context).colorScheme.primary 
                              : Theme.of(context).colorScheme.onSurface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.tune, color: Theme.of(context).colorScheme.surface, size: 16),
                      ),
                      itemBuilder: (context) => [
                        const PopupMenuItem<dynamic>(
                          value: 'clear',
                          child: Text('All Categories'),
                        ),
                        ...TaskCategory.values.map((cat) => PopupMenuItem<dynamic>(
                          value: cat,
                          child: Text(cat.name[0].toUpperCase() + cat.name.substring(1)),
                        )),
                      ],
                    )
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: const Text(
                'Ongoing tasks',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: openTasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: totalOpenTasks.isEmpty 
                                  ? Colors.green.withValues(alpha: 0.05)
                                  : Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              totalOpenTasks.isEmpty ? Icons.task_alt_rounded : Icons.search_off_rounded, 
                              size: 64, 
                              color: totalOpenTasks.isEmpty 
                                  ? Colors.green.shade300 
                                  : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            totalOpenTasks.isEmpty ? 'All caught up!' : 'No matching tasks',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            totalOpenTasks.isEmpty 
                                ? "You don't have any pending tasks."
                                : "Try adjusting your search or filter.",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ).animate().fade(duration: 400.ms).scale(begin: const Offset(0.9, 0.9), delay: 100.ms),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        await Future.delayed(const Duration(milliseconds: 500));
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24).copyWith(bottom: 100),
                        clipBehavior: Clip.antiAlias, // Ensures corners round the list items
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1C1C1E) : Colors.white,
                          borderRadius: BorderRadius.circular(10), // True iOS inset group radius
                        ),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: openTasks.length,
                          itemBuilder: (context, index) {
                            final task = openTasks[index];
                            final isLast = index == openTasks.length - 1;
                          
                          return Dismissible(
                            key: Key('todo_${task.id}_${task.startTime?.toIso8601String() ?? 'none'}'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Icon(Icons.delete_outline, color: Colors.white, size: 32),
                            ),
                            confirmDismiss: (direction) async {
                              final db = ref.read(dbServiceProvider);
                              if (task.recurrence != RecurrenceType.none) {
                                final result = await Get.dialog<String>(
                                  AlertDialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    title: const Text('Recurring Task'),
                                    content: const Text('Do you want to apply this deletion to this event only, or to all events in the series?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Get.back(result: 'single'),
                                        child: const Text('This event only'),
                                      ),
                                      TextButton(
                                        onPressed: () => Get.back(result: 'all'),
                                        child: const Text('All events in series'),
                                      ),
                                    ],
                                  ),
                                );
                                
                                if (result == null) return false;
                                
                                if (result == 'single') {
                                  final originalTask = await db.getTask(task.id);
                                  if (originalTask != null) {
                                    final dates = originalTask.excludedDates?.toList() ?? [];
                                    final targetDate = task.startTime ?? DateTime.now();
                                    
                                    final alreadyExcluded = dates.any((d) => 
                                      d.year == targetDate.year && d.month == targetDate.month && d.day == targetDate.day
                                    );
                                    
                                    if (!alreadyExcluded) {
                                      dates.add(DateTime(targetDate.year, targetDate.month, targetDate.day));
                                      originalTask.excludedDates = dates;
                                      await db.saveTimeTask(originalTask);
                                    }
                                  }
                                } else if (result == 'all') {
                                  await db.deleteTimeTask(task.id);
                                }
                              } else {
                                await db.deleteTimeTask(task.id);
                              }
                              
                              return true;
                            },
                            child: _TodoCard(task: task, index: index, isLast: isLast)
                                .animate(delay: (index * 50).ms)
                                .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                                .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutQuart),
                          );
                        },
                      ),
                    ),
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text('Database Schema Mismatch', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'An older task is causing a memory layout corruption error.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final db = ref.read(dbServiceProvider);
                await db.clearAllData();
              },
              icon: const Icon(Icons.delete_forever),
              label: const Text('Wipe Corrupt Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withValues(alpha: 0.2),
                foregroundColor: Colors.redAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodoCard extends ConsumerWidget {
  final TimeTask task;
  final int index;
  final bool isLast;

  const _TodoCard({required this.task, required this.index, this.isLast = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Aesthetic colors based on category
    final categoryColors = {
      TaskCategory.work: const Color(0xFF6366F1),
      TaskCategory.personal: const Color(0xFFEC4899),
      TaskCategory.health: const Color(0xFF14B8A6),
      TaskCategory.finance: const Color(0xFFF59E0B),
      TaskCategory.other: const Color(0xFF8B5CF6),
    };

    final accentColor = categoryColors[task.category] ?? categoryColors[TaskCategory.other]!;
    
    final timeFormat = DateFormat.jm();
    final timeString = task.startTime != null ? timeFormat.format(task.startTime!) : '';
    
    // Check if overdue
    bool isPastPending = false;
    String overdueText = '';
    
    if (task.startTime != null && !task.isCompleted && task.recurrence == RecurrenceType.none) {
      final now = DateTime.now();
      if (task.startTime!.isBefore(now)) {
        isPastPending = true;
        
        final today = DateTime(now.year, now.month, now.day);
        final taskDate = DateTime(task.startTime!.year, task.startTime!.month, task.startTime!.day);
        
        if (taskDate.isBefore(today)) {
          final diffInDays = today.difference(taskDate).inDays;
          if (diffInDays == 1) {
            overdueText = 'OVERDUE FROM YESTERDAY';
          } else {
            overdueText = 'OVERDUE FROM ${DateFormat('MMM d').format(taskDate).toUpperCase()}';
          }
        } else {
          overdueText = 'OVERDUE';
        }
      }
    }

    final textColor = Theme.of(context).colorScheme.onSurface;

    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent, // True Apple List Cell
        border: isLast ? null : Border( // Only draw border if not the last item
          bottom: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
            width: 0.5, // Hairline separator
          ),
        ),
      ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
                onDoubleTap: () {
                  Get.bottomSheet(
                    TaskEntryDialog(existingTask: task),
                    isScrollControlled: true,
                  );
                },
                onTap: () async {
                  final db = ref.read(dbServiceProvider);
                  task.isCompleted = !task.isCompleted;
                  await db.saveTimeTask(task, userToggledCompletionState: task.isCompleted);
                  
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Native list padding
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Classic Faint Circular Checkbox
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: task.isCompleted ? accentColor : Colors.grey.withValues(alpha: 0.3), 
                          width: task.isCompleted ? 0 : 1.5 // Faint outline when empty
                        ),
                        color: task.isCompleted ? accentColor : Colors.transparent,
                      ),
                      child: task.isCompleted
                          ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isPastPending)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                overdueText, 
                                style: const TextStyle(
                                  color: Colors.redAccent, 
                                  fontSize: 12, 
                                  fontWeight: FontWeight.w500
                                ),
                              ),
                            ),
                          Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 16, // Strict compact scaling
                              fontWeight: FontWeight.w600,
                              color: task.isCompleted ? textColor.withValues(alpha: 0.4) : textColor.withValues(alpha: 0.9),
                              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            task.category.name,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w400, // Minimalist category text
                            ),
                          ),
                          if (task.notes.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              task.notes,
                              style: TextStyle(
                                fontSize: 13,
                                color: task.isCompleted ? textColor.withValues(alpha: 0.3) : textColor.withValues(alpha: 0.6),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Metadata Pin - Float right for minimalism
                    if (task.type == TaskType.meeting || task.startTime != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (task.type == TaskType.meeting)
                            Icon(
                              Icons.event_rounded,
                              size: 14,
                              color: Colors.grey.withValues(alpha: 0.6),
                            ),
                          if (timeString.isNotEmpty) ...[
                            if (task.type == TaskType.meeting) const SizedBox(width: 4),
                            Text(
                              timeString,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey.withValues(alpha: 0.8), // Non-distracting time
                              ),
                            ),
                          ]
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}
