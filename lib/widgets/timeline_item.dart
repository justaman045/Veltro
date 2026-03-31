import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/time_task.dart';
import '../providers/providers.dart';
import 'task_entry_dialog.dart';

class TimelineItem extends ConsumerWidget {
  final List<TimeTask> tasks;
  final DateTime timeSlot;
  final bool isFirst;
  final bool isLast;
  final int index;

  const TimelineItem({
    super.key,
    required this.tasks,
    required this.timeSlot,
    required this.isFirst,
    required this.isLast,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Aesthetic colors based on index or type
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final categoryColors = {
      TaskCategory.work: const Color(0xFF6366F1),
      TaskCategory.personal: const Color(0xFFEC4899),
      TaskCategory.health: const Color(0xFF14B8A6),
      TaskCategory.finance: const Color(0xFFF59E0B),
      TaskCategory.other: const Color(0xFF8B5CF6),
    };

    final lineColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1);

    if (tasks.isEmpty) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Time Text Column
            SizedBox(
              width: 65,
              child: Padding(
                padding: const EdgeInsets.only(top: 32, left: 16),
                child: Text(
                  DateFormat('hh:mm a').format(timeSlot),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Timeline Line & Dot column
            SizedBox(
              width: 20,
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isFirst ? Colors.transparent : lineColor,
                    ),
                  ),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.3), width: 3),
                      color: Theme.of(context).cardTheme.color,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isLast ? Colors.transparent : lineColor,
                    ),
                  ),
                ],
              ),
            ),
            
            // Card content space
            const Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: 24, top: 12, bottom: 12, left: 8),
                child: SizedBox(height: 60, width: double.infinity), // Minimum height for an empty hour block
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(tasks.length, (taskIndex) {
        final task = tasks[taskIndex];
        final bool isFirstNode = isFirst && taskIndex == 0;
        final bool isLastNode = isLast && taskIndex == tasks.length - 1;

        final bool isPastPending = task.startTime != null && 
                            task.startTime!.isBefore(DateTime.now()) &&
                            !task.isCompleted;
        
        String overdueText = 'OVERDUE';
        if (isPastPending && task.recurrence == RecurrenceType.none) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final taskDate = DateTime(task.startTime!.year, task.startTime!.month, task.startTime!.day);
          if (taskDate.isBefore(today)) {
            final diffInDays = today.difference(taskDate).inDays;
            if (diffInDays == 1) {
              overdueText = 'OVERDUE YESTERDAY';
            } else {
              overdueText = 'OVERDUE ${DateFormat('MMM d').format(taskDate).toUpperCase()}';
            }
          }
        }

        final taskTextColor = categoryColors[task.category] ?? categoryColors[TaskCategory.other]!;
        final timelineDotColor = taskTextColor;
        final textColor = Theme.of(context).colorScheme.onSurface;

        final taskWidget = Padding(
          padding: EdgeInsets.only(bottom: taskIndex == tasks.length - 1 ? 0 : 12.0),
          child: GestureDetector(
            onDoubleTap: () {
              Get.bottomSheet(
                TaskEntryDialog(existingTask: task),
                isScrollControlled: true,
              );
            },
            onTap: () async {
              if (task.type == TaskType.task || task.type == TaskType.meeting) {
                final db = ref.read(dbServiceProvider);
                if (task.recurrence != RecurrenceType.none) {
                  final originalTask = await db.getTask(task.id);
                  if (originalTask != null) {
                    final dates = originalTask.completedDates?.toList() ?? [];
                    final targetDate = task.startTime ?? DateTime.now();
                    
                    final wasCompleted = dates.any((d) => 
                      d.year == targetDate.year && 
                      d.month == targetDate.month && 
                      d.day == targetDate.day
                    );
                    
                    if (wasCompleted) {
                      dates.removeWhere((d) => 
                        d.year == targetDate.year && 
                        d.month == targetDate.month && 
                        d.day == targetDate.day
                      );
                    } else {
                      dates.add(DateTime(targetDate.year, targetDate.month, targetDate.day));
                    }
                    originalTask.completedDates = dates;
                    await db.saveTimeTask(originalTask, userToggledCompletionState: !wasCompleted);
                  }
                } else {
                  task.isCompleted = !task.isCompleted;
                  await db.saveTimeTask(task, userToggledCompletionState: task.isCompleted);
                }
              }
            },
            child: Container(
              width: double.infinity, // Ensures all cards have uniform full width
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(20), // iOS Notification Card style
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.all(tasks.length > 2 ? 8 : (tasks.length > 1 ? 12 : 16)), // Proper breathing room for notification card
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                          if (isPastPending)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                overdueText,
                                style: TextStyle(
                                  color: Colors.redAccent, 
                                  fontSize: tasks.length > 1 ? 10 : 12, 
                                  fontWeight: FontWeight.w500
                                ),
                              ),
                            ),
                         Row(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             // Circular Checkbox
                             Container(
                               margin: const EdgeInsets.only(right: 12, top: 2),
                               width: 22,
                               height: 22,
                               decoration: BoxDecoration(
                                 shape: BoxShape.circle,
                                 color: task.isCompleted ? Theme.of(context).colorScheme.primary : Colors.transparent,
                                 border: Border.all(
                                   color: task.isCompleted ? Theme.of(context).colorScheme.primary : Colors.grey.withValues(alpha: 0.3),
                                   width: 2,
                                 ),
                               ),
                               child: task.isCompleted
                                   ? const Icon(Icons.check, size: 14, color: Colors.white)
                                   : null,
                             ),
                             Expanded(
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Text(
                                    task.title,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: task.isCompleted ? textColor.withValues(alpha: 0.4) : textColor.withValues(alpha: 0.9),
                                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Text(
                                          task.category.name,
                                          style: TextStyle(
                                            color: taskTextColor,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        if (task.startTime != null || task.endTime != null) ...[
                                          Text(
                                            ' • ',
                                            style: TextStyle(
                                              color: textColor.withValues(alpha: 0.4),
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            task.startTime != null 
                                              ? DateFormat('h:mm a').format(task.startTime!) 
                                                + (task.endTime != null ? ' - ${DateFormat('h:mm a').format(task.endTime!)}' : '')
                                              : 'Ends ${DateFormat('h:mm a').format(task.endTime!)}',
                                            style: TextStyle(
                                              color: textColor.withValues(alpha: 0.6),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  if (task.notes.isNotEmpty) ...[
                                    const SizedBox(height: 8),
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
                           ],
                         ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        final dragDropConstruct = LongPressDraggable<TimeTask>(
          data: task,
          feedback: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.7, // Estimate width
              child: Opacity(
                opacity: 0.8,
                child: taskWidget, // visual appearance while dragging
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: taskWidget, // What's left behind
          ),
          child: Dismissible(
            key: Key('timeline_${task.id}_${task.startTime?.toIso8601String() ?? 'none'}'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              margin: EdgeInsets.only(bottom: taskIndex == tasks.length - 1 ? 0 : 12.0),
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
            child: taskWidget,
          ),
        );

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Individual Time Text Column for this exactly task
              SizedBox(
                width: 65,
                child: Padding(
                  padding: const EdgeInsets.only(top: 32, left: 16),
                  child: Text(
                    task.startTime != null ? DateFormat('hh:mm a').format(task.startTime!) : DateFormat('hh:mm a').format(timeSlot),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Timeline Line & Dot column connecting individual tasks
              SizedBox(
                width: 20,
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        width: 2,
                        color: isFirstNode ? Colors.transparent : lineColor,
                      ),
                    ),
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: timelineDotColor, width: 3),
                        color: Theme.of(context).cardTheme.color,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: 2,
                        color: isLastNode ? Colors.transparent : lineColor,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Card content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 24, top: 12, bottom: 0, left: 8),
                  child: dragDropConstruct,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
