import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/time_task.dart';
import '../providers/providers.dart';
import '../utils/animations.dart';
import '../widgets/task_entry_dialog.dart';
import 'settings_view.dart';
import 'pomodoro_view.dart';
import '../utils/app_colors.dart';

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

        final highPriority = openTasks.where((t) => t.priority == TaskPriority.high).toList();
        final mediumPriority = openTasks.where((t) => t.priority == TaskPriority.medium).toList();
        final lowPriority = openTasks.where((t) => t.priority == TaskPriority.low).toList();
        var completedTasks = tasks.where((t) => t.isCompleted).toList();
        if (query.isNotEmpty) {
          completedTasks = completedTasks.where((t) =>
            t.title.toLowerCase().contains(query) ||
            t.notes.toLowerCase().contains(query)
          ).toList();
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
                    child: CircleAvatar(
                      radius: 18,
                      backgroundImage: ref.watch(authServiceProvider).currentUser?.photoURL != null
                          ? NetworkImage(ref.watch(authServiceProvider).currentUser!.photoURL!)
                          : null,
                      backgroundColor: Colors.transparent,
                      child: ref.watch(authServiceProvider).currentUser?.photoURL == null
                          ? const Icon(Icons.person_outline, size: 18)
                          : null,
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
                  borderRadius: BorderRadius.circular(16), // Soft iOS Corners
                  gradient: context.subtleGradient,
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
            
            const SizedBox(height: 16),
            Expanded(
              child: openTasks.isEmpty && completedTasks.isEmpty
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
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                          ),
                        ],
                      ).animate().fade(duration: 400.ms).scale(begin: const Offset(0.9, 0.9), delay: 100.ms),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        await Future.delayed(const Duration(milliseconds: 500));
                      },
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 24).copyWith(bottom: 100),
                        children: [
                          // Priority groups
                          if (highPriority.isNotEmpty) ...[
                            _PriorityHeader(
                              label: 'High Priority',
                              count: highPriority.length,
                              color: TimeTask.priorityColors[TaskPriority.high]!,
                            ),
                            _TodoGroup(tasks: highPriority),

                            _TodoGroup(tasks: mediumPriority),

                            _TodoGroup(tasks: lowPriority),
                            const SizedBox(height: 16),
                          ],
                          // Completed collapsible
                          if (completedTasks.isNotEmpty)
                            _CompletedSection(tasks: completedTasks, ref: ref),
                        ],
                      ),
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text('Task Load Error', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  err.toString().length > 200 ? '${err.toString().substring(0, 200)}...' : err.toString(),
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
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
                  try {
                    final user = FirebaseAuth.instance.currentUser;
                    final userEmail = user?.email;
                    if (userEmail == null) {
                      Get.back();
                      Get.snackbar('Error', 'No user logged in');
                      return;
                    }
                    final docs = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(userEmail)
                        .collection('tasks')
                        .get();

                    final problems = <String, String>{};
                    for (final doc in docs.docs) {
                      try {
                        final data = doc.data();
                        // Test with strict parse to find docs that would have failed
                        if (data['startTime'] != null && data['startTime'] is! String) {
                          problems[doc.id] = 'startTime is ${data['startTime'].runtimeType} (expected String)';
                        }
                        if (data['endTime'] != null && data['endTime'] is! String) {
                          problems[doc.id] = 'endTime is ${data['endTime'].runtimeType} (expected String)';
                        }
                        final dates = data['completedDates'];
                        if (dates != null && dates is List) {
                          for (final d in dates) {
                            if (d is! String) {
                              problems[doc.id] = 'completedDates item is ${d.runtimeType} (expected String)';
                            }
                          }
                        }
                        final excl = data['excludedDates'];
                        if (excl != null && excl is List) {
                          for (final d in excl) {
                            if (d is! String) {
                              problems[doc.id] = 'excludedDates item is ${d.runtimeType} (expected String)';
                            }
                          }
                        }
                      } catch (e) {
                        problems[doc.id] = e.toString();
                      }
                    }

                    Get.back();

                    if (problems.isEmpty) {
                      Get.dialog(AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: const Text('All Clear'),
                        content: const Text('No documents with type mismatches found. The error may be transient.'),
                        actions: [TextButton(onPressed: () => Get.back(), child: const Text('OK'))],
                      ));
                    } else {
                      final buf = StringBuffer();
                      problems.forEach((id, issue) => buf.writeln('• $id\n  $issue\n'));
                      Get.dialog(AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: Text('${problems.length} Document(s) with Issues'),
                        content: SingleChildScrollView(
                          child: Text(buf.toString(), style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                        ),
                        actions: [TextButton(onPressed: () => Get.back(), child: const Text('OK'))],
                      ));
                    }
                  } catch (e) {
                    Get.back();
                    Get.snackbar('Inspect Failed', e.toString());
                  }
                },
                icon: const Icon(Icons.search),
                label: const Text('Inspect Documents'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orangeAccent,
                  side: BorderSide(color: Colors.orangeAccent.withValues(alpha: 0.3)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Helper widgets ───────────────────────────────────────────────────────────

class _PriorityHeader extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _PriorityHeader({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ),
        ],
      ),
    );
  }
}

class _TodoGroup extends ConsumerWidget {
  final List<TimeTask> tasks;

  const _TodoGroup({required this.tasks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: tasks.asMap().entries.map((entry) {
          final index = entry.key;
          final task = entry.value;
          final isLast = index == tasks.length - 1;
            return Dismissible(
              key: Key('todo_${task.id}_${task.startTime?.toIso8601String() ?? 'none'}'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                color: Colors.redAccent.withValues(alpha: 0.85),
                child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
              ),
              confirmDismiss: (direction) async {
                final db = ref.read(dbServiceProvider);
                if (task.recurrence != RecurrenceType.none) {
                  final result = await Get.dialog<String>(
                    AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Text('Recurring Task'),
                      content: const Text('Delete this event only, or all events in the series?'),
                      actions: [
                        TextButton(onPressed: () => Get.back(result: 'single'), child: const Text('This event only')),
                        TextButton(onPressed: () => Get.back(result: 'all'), child: const Text('All events')),
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
                          d.year == targetDate.year && d.month == targetDate.month && d.day == targetDate.day);
                      if (!alreadyExcluded) {
                        dates.add(DateTime(targetDate.year, targetDate.month, targetDate.day));
                        originalTask.excludedDates = dates;
                        await db.saveTimeTask(originalTask);
                      }
                    }
                  } else {
                    await db.deleteTimeTask(task.id, suppressSnackbar: true);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: const Text('Task deleted'),
                        duration: const Duration(seconds: 4),
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () {},
                        ),
                      ));
                    }
                  }
                } else {
                  final taskCopy = TimeTask()
                    ..id = task.id
                    ..title = task.title
                    ..notes = task.notes
                    ..startTime = task.startTime
                    ..endTime = task.endTime
                    ..isCompleted = task.isCompleted
                    ..recurrence = task.recurrence
                    ..completedDates = task.completedDates?.toList()
                    ..excludedDates = task.excludedDates?.toList()
                    ..type = task.type
                    ..category = task.category
                    ..priority = task.priority
                    ..subtasks = task.subtasks?.map((s) => Map<String, dynamic>.from(s)).toList();

                  await db.deleteTimeTask(task.id, suppressSnackbar: true);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: const Text('Task deleted'),
                      duration: const Duration(seconds: 4),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () {
                          db.saveTimeTask(taskCopy);
                        },
                      ),
                    ));
                  }
                }
                return true;
              },
            child: _TodoCard(task: task, index: index, isLast: isLast)
                .animate(delay: (index * 40).ms)
                .fadeIn(duration: 350.ms)
                .slideY(begin: 0.08, end: 0, duration: 350.ms, curve: Curves.easeOut),
          );
        }).toList(),
      ),
    );
  }
}

class _CompletedSection extends ConsumerStatefulWidget {
  final List<TimeTask> tasks;
  final WidgetRef ref;

  const _CompletedSection({required this.tasks, required this.ref});

  @override
  ConsumerState<_CompletedSection> createState() => _CompletedSectionState();
}

class _CompletedSectionState extends ConsumerState<_CompletedSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: animDuration(context, ms: 250),
                  child: Icon(
                    Icons.expand_more_rounded,
                    size: 18,
                    color: textColor.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Completed',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textColor.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.tasks.length}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.green),
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: widget.tasks.asMap().entries.map((entry) {
                final index = entry.key;
                final task = entry.value;
                return _TodoCard(task: task, index: index, isLast: index == widget.tasks.length - 1);
              }).toList(),
            ),
          ),
          crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: animDuration(context, ms: 300),
          sizeCurve: Curves.easeOut,
        ),
      ],
    );
  }
}

class _TodoCard extends ConsumerWidget {
  final TimeTask task;
  final int index;
  final bool isLast;

  const _TodoCard({required this.task, required this.index, this.isLast = false});

  int _computeStreak(TimeTask task) {
    if (task.recurrence == RecurrenceType.none || task.completedDates == null) return 0;
    const maxStreak = 366;
    var streak = 0;
    var checkDate = DateTime.now();
    checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day);
    while (streak < maxStreak) {
      final done = task.completedDates!.any((d) =>
        d.year == checkDate.year && d.month == checkDate.month && d.day == checkDate.day);
      if (!done) break;
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    return streak;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final accentColor = TimeTask.categoryColors[task.category] ?? TimeTask.categoryColors[TaskCategory.other]!;
    
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

    final priorityColor = TimeTask.priorityColors[task.priority]!;
    final streak = _computeStreak(task);

    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: isLast ? null : Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
            width: 0.5,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onDoubleTap: () {
            Get.bottomSheet(TaskEntryDialog(existingTask: task), isScrollControlled: true);
          },
          onTap: () async {
            final db = ref.read(dbServiceProvider);
            final updated = TimeTask()
              ..id = task.id
              ..title = task.title
              ..notes = task.notes
              ..startTime = task.startTime
              ..endTime = task.endTime
              ..isCompleted = !task.isCompleted
              ..recurrence = task.recurrence
              ..completedDates = task.completedDates?.toList()
              ..excludedDates = task.excludedDates?.toList()
              ..type = task.type
              ..category = task.category
              ..priority = task.priority
              ..subtasks = task.subtasks?.map((s) => Map<String, dynamic>.from(s)).toList();
            await db.saveTimeTask(updated, userToggledCompletionState: updated.isCompleted);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Priority accent line
                Container(
                  width: 3, height: 40,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(color: priorityColor, borderRadius: BorderRadius.circular(2)),
                ),
                // Checkbox
                AnimatedContainer(
                  duration: kAnimNormal,
                  curve: Curves.easeInOut,
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: task.isCompleted ? accentColor : Colors.grey.withValues(alpha: 0.3), width: task.isCompleted ? 0 : 1.5),
                    color: task.isCompleted ? accentColor : Colors.transparent,
                  ),
                  child: AnimatedScale(
                    scale: task.isCompleted ? 1.0 : 0.0,
                    duration: kAnimFast,
                    curve: Curves.easeOutBack,
                    child: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isPastPending)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(overdueText, style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w500)),
                        ),
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600,
                          color: task.isCompleted ? textColor.withValues(alpha: 0.4) : textColor.withValues(alpha: 0.9),
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(task.category.name, style: TextStyle(color: accentColor, fontSize: 13, fontWeight: FontWeight.w400)),
                          if (streak > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.local_fire_department_rounded, size: 10, color: Colors.orange),
                                  const SizedBox(width: 2),
                                  Text('$streak', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.orange)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (task.notes.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.notes,
                          style: TextStyle(fontSize: 13, color: task.isCompleted ? textColor.withValues(alpha: 0.3) : textColor.withValues(alpha: 0.6)),
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      // Subtask progress
                      if (task.hasSubtasks) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: task.totalSubtaskCount > 0 ? task.completedSubtaskCount / task.totalSubtaskCount : 0,
                                  minHeight: 3,
                                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                                  valueColor: AlwaysStoppedAnimation(accentColor),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text('${task.completedSubtaskCount}/${task.totalSubtaskCount}',
                                style: TextStyle(fontSize: 10, color: textColor.withValues(alpha: 0.5), fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Right actions
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!task.isCompleted)
                      GestureDetector(
                        onTap: () => Get.to(() => PomodoroView(taskTitle: task.title)),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.timer_rounded, size: 14, color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                    if (task.type == TaskType.meeting || timeString.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (task.type == TaskType.meeting)
                            Icon(Icons.event_rounded, size: 12, color: Colors.grey.withValues(alpha: 0.6)),
                          if (timeString.isNotEmpty) ...[
                            if (task.type == TaskType.meeting) const SizedBox(width: 2),
                            Text(timeString, style: TextStyle(fontSize: 12, color: Colors.grey.withValues(alpha: 0.8))),
                          ],
                        ],
                      ),
                    ],
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
