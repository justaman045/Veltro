import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/time_task.dart';
import '../providers/providers.dart';
import 'task_entry_dialog.dart';
import '../utils/app_colors.dart';
import '../utils/animations.dart';
import '../screens/pomodoro_view.dart';

class TaskCard extends ConsumerStatefulWidget {
  final TimeTask task;
  final double height;

  const TaskCard({super.key, required this.task, required this.height});

  @override
  ConsumerState<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends ConsumerState<TaskCard> {
  bool _expanded = false;

  int _computeStreak(TimeTask task) {
    if (task.recurrence == RecurrenceType.none || task.completedDates == null) return 0;
    const maxStreak = 366;
    var streak = 0;
    var checkDate = DateTime.now();
    checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day);
    while (streak < maxStreak) {
      final done = task.completedDates!.any((d) =>
          d.year == checkDate.year &&
          d.month == checkDate.month &&
          d.day == checkDate.day);
      if (!done) break;
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Future<void> _toggleComplete() async {
    final task = widget.task;
    if (task.type != TaskType.task && task.type != TaskType.meeting) return;
    final db = ref.read(dbServiceProvider);
    if (task.recurrence != RecurrenceType.none) {
      final originalTask = await db.getTask(task.id);
      if (originalTask != null) {
        final dates = originalTask.completedDates?.toList() ?? [];
        final targetDate = task.startTime ?? DateTime.now();
        final wasCompleted = dates.any((d) =>
            d.year == targetDate.year &&
            d.month == targetDate.month &&
            d.day == targetDate.day);
        if (wasCompleted) {
          dates.removeWhere((d) =>
              d.year == targetDate.year &&
              d.month == targetDate.month &&
              d.day == targetDate.day);
        } else {
          dates.add(DateTime(targetDate.year, targetDate.month, targetDate.day));
        }
        originalTask.completedDates = dates;
        await db.saveTimeTask(originalTask, userToggledCompletionState: !wasCompleted);
      }
    } else {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final categoryColor =
        TimeTask.categoryColors[task.category] ?? TimeTask.categoryColors[TaskCategory.other]!;
    final priorityColor = TimeTask.priorityColors[task.priority]!;
    final streak = _computeStreak(task);

    final now = DateTime.now();
    final isPastPending = task.startTime != null &&
        task.startTime!.isBefore(now) &&
        !task.isCompleted &&
        task.recurrence == RecurrenceType.none;

    String overdueText = 'OVERDUE';
    if (isPastPending) {
      final today = DateTime(now.year, now.month, now.day);
      final taskDate =
          DateTime(task.startTime!.year, task.startTime!.month, task.startTime!.day);
      if (taskDate.isBefore(today)) {
        final diff = today.difference(taskDate).inDays;
        overdueText = diff == 1
            ? 'OVERDUE YESTERDAY'
            : 'OVERDUE ${DateFormat('MMM d').format(taskDate).toUpperCase()}';
      }
    }

    final priorityLabel = switch (task.priority) {
      TaskPriority.high => 'H',
      TaskPriority.medium => 'M',
      TaskPriority.low => 'L',
    };

    String? timeRangeString;
    if (task.startTime != null) {
      timeRangeString = DateFormat('h:mm a').format(task.startTime!);
      if (task.endTime != null) {
        timeRangeString += ' – ${DateFormat('h:mm a').format(task.endTime!)}';
      }
    }

    final card = SizedBox(
      height: widget.height,
      child: Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: categoryColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            color: categoryColor.withValues(alpha: isDark ? 0.12 : 0.07),
            child: Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 4, height: 4,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: categoryColor),
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            task.category.name[0].toUpperCase() + task.category.name.substring(1),
                            style: TextStyle(color: categoryColor, fontSize: 9, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                if (isPastPending)
                  Flexible(
                    child: Text(
                      overdueText,
                      style: const TextStyle(
                        color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else if (streak > 0) ...[
                  const Icon(Icons.local_fire_department_rounded, size: 10, color: Colors.orange),
                  const SizedBox(width: 2),
                  Text('$streak', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.orange)),
                ],
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    priorityLabel,
                    style: TextStyle(color: priorityColor, fontSize: 8, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 4),
                if (!task.isCompleted)
                  Tooltip(
                    message: 'Pomodoro Timer',
                    child: GestureDetector(
                      onTap: () => Get.to(() => PomodoroView(taskTitle: task.title)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                        decoration: BoxDecoration(
                          color: context.gradientPrimary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: context.gradientPrimary.withValues(alpha: 0.2)),
                        ),
                        child: Icon(Icons.timer_rounded, size: 11, color: context.gradientPrimary),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 2, 8, 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _toggleComplete,
                  child: AnimatedContainer(
                    duration: kAnimNormal,
                    curve: Curves.easeInOut,
                    width: 16, height: 16,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: task.isCompleted ? Theme.of(context).colorScheme.primary : Colors.transparent,
                      border: Border.all(
                        color: task.isCompleted ? Theme.of(context).colorScheme.primary : Colors.grey.withValues(alpha: 0.35),
                        width: task.isCompleted ? 0 : 2,
                      ),
                    ),
                    child: AnimatedScale(
                      scale: task.isCompleted ? 1.0 : 0.0,
                      duration: kAnimFast,
                      curve: Curves.easeOutBack,
                      child: const Icon(Icons.check, size: 11, color: Colors.white),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: task.isCompleted ? textColor.withValues(alpha: 0.4) : textColor.withValues(alpha: 0.9),
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (timeRangeString != null) ...[
                        const SizedBox(height: 1),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule_rounded, size: 10, color: textColor.withValues(alpha: 0.4)),
                            Flexible(
                              child: Text(
                                timeRangeString,
                                style: TextStyle(fontSize: 9, color: textColor.withValues(alpha: 0.55), fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (task.notes.isNotEmpty)
                        AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          alignment: Alignment.topCenter,
                          child: Text(
                            task.notes,
                            style: TextStyle(
                              fontSize: 11,
                              color: task.isCompleted ? textColor.withValues(alpha: 0.3) : textColor.withValues(alpha: 0.6),
                            ),
                            maxLines: _expanded ? 4 : 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (task.hasSubtasks) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: task.totalSubtaskCount > 0
                                      ? task.completedSubtaskCount / task.totalSubtaskCount
                                      : 0,
                                  minHeight: 3,
                                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                                  valueColor: AlwaysStoppedAnimation(categoryColor),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${task.completedSubtaskCount}/${task.totalSubtaskCount}',
                              style: TextStyle(fontSize: 10, color: textColor.withValues(alpha: 0.5), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                      AnimatedCrossFade(
                        firstChild: const SizedBox.shrink(),
                        secondChild: Column(
                          children: (task.subtasks ?? []).asMap().entries.map<Widget>((entry) {
                            final i = entry.key;
                            final subtask = entry.value;
                            final isDone = subtask['done'] == true;
                            return GestureDetector(
                              onTap: () async {
                                final updatedSubtasks = (task.subtasks ?? [])
                                    .map((s) => Map<String, dynamic>.from(s)).toList();
                                updatedSubtasks[i]['done'] = !isDone;
                                final updatedTask = TimeTask()
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
                                  ..subtasks = updatedSubtasks;
                                await ref.read(dbServiceProvider).saveTimeTask(updatedTask);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 14, height: 14,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isDone ? categoryColor : Colors.transparent,
                                        border: Border.all(
                                          color: isDone ? categoryColor : Colors.grey.withValues(alpha: 0.4),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: isDone ? const Icon(Icons.check, size: 8, color: Colors.white) : null,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        subtask['title'] ?? '',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDone ? textColor.withValues(alpha: 0.4) : textColor.withValues(alpha: 0.75),
                                          decoration: isDone ? TextDecoration.lineThrough : null,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 250),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );

    final dismissibleCard = Dismissible(
      key: Key('dis_${task.id}_${task.startTime?.millisecondsSinceEpoch ?? 0}'),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        await _toggleComplete();
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              task.isCompleted ? Icons.remove_done_rounded : Icons.check_circle_rounded,
              color: Colors.green, size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              task.isCompleted ? 'Reopen' : 'Complete',
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 11),
            ),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        onDoubleTap: () => Get.bottomSheet(TaskEntryDialog(existingTask: task), isScrollControlled: true),
        child: card,
      ),
    );

    return dismissibleCard;
  }
}
