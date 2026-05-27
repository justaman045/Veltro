import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/time_task.dart';
import '../providers/providers.dart';
import '../widgets/task_entry_dialog.dart';
import '../utils/app_colors.dart';
import '../screens/pomodoro_view.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lineColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.07);

    if (tasks.isEmpty) {
      return SizedBox(
        height: 48,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 56,
              child: Text(
                DateFormat('h a').format(timeSlot),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Container(height: 0.5, color: lineColor)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(
        tasks.length,
        (i) => Padding(
          padding: EdgeInsets.only(
            top: i == 0 ? 8 : 6,
            bottom: i == tasks.length - 1 ? 8 : 0,
          ),
          child: _TaskRow(
            key: Key('tr_${tasks[i].id}'),
            task: tasks[i],
            timeSlot: timeSlot,
          ),
        ),
      ),
    );
  }
}

class _TaskRow extends ConsumerStatefulWidget {
  final TimeTask task;
  final DateTime timeSlot;

  const _TaskRow({super.key, required this.task, required this.timeSlot});

  @override
  ConsumerState<_TaskRow> createState() => _TaskRowState();
}

class _TaskRowState extends ConsumerState<_TaskRow> {
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

    // Visual card (no gesture handling — gestures are on the wrapper)
    final card = Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        gradient: context.subtleGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header strip ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: categoryColor.withValues(alpha: isDark ? 0.12 : 0.07),
            child: Row(
              children: [
                // Category chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration:
                            BoxDecoration(shape: BoxShape.circle, color: categoryColor),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        task.category.name[0].toUpperCase() +
                            task.category.name.substring(1),
                        style: TextStyle(
                            color: categoryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Status badge (overdue OR streak)
                if (isPastPending)
                  Flexible(
                    child: Text(
                      overdueText,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else if (streak > 0) ...[
                  const Icon(Icons.local_fire_department_rounded,
                      size: 12, color: Colors.orange),
                  const SizedBox(width: 2),
                  Text(
                    '$streak',
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700, color: Colors.orange),
                  ),
                ],
                const Spacer(),
                // Priority badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    priorityLabel,
                    style: TextStyle(
                        color: priorityColor, fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 6),
                // Pomodoro timer button
                if (!task.isCompleted)
                  Tooltip(
                    message: 'Pomodoro Timer',
                    child: GestureDetector(
                      onTap: () => Get.to(() => PomodoroView(taskTitle: task.title)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: context.gradientPrimary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: context.gradientPrimary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer_rounded, size: 13, color: context.gradientPrimary),
                            const SizedBox(width: 3),
                            Text('Focus', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: context.gradientPrimary)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // ── Content area ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox — tapping this completes the task
                GestureDetector(
                  onTap: _toggleComplete,
                  child: Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(top: 1, right: 10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: task.isCompleted
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: task.isCompleted
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.withValues(alpha: 0.35),
                        width: 2,
                      ),
                    ),
                    child: task.isCompleted
                        ? const Icon(Icons.check, size: 13, color: Colors.white)
                        : null,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: task.isCompleted
                              ? textColor.withValues(alpha: 0.4)
                              : textColor.withValues(alpha: 0.9),
                          decoration:
                              task.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      // Time — own line, no overflow risk
                      if (timeRangeString != null) ...[
                        const SizedBox(height: 3),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule_rounded,
                                size: 11, color: textColor.withValues(alpha: 0.4)),
                            const SizedBox(width: 3),
                            Text(
                              timeRangeString,
                              style: TextStyle(
                                fontSize: 12,
                                color: textColor.withValues(alpha: 0.55),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                      // Notes — always visible, more lines when expanded
                      if (task.notes.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          alignment: Alignment.topCenter,
                          child: Text(
                            task.notes,
                            style: TextStyle(
                              fontSize: 13,
                              color: task.isCompleted
                                  ? textColor.withValues(alpha: 0.3)
                                  : textColor.withValues(alpha: 0.6),
                            ),
                            maxLines: _expanded ? 4 : 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      // Subtask progress bar (always shown if has subtasks)
                      if (task.hasSubtasks) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: task.totalSubtaskCount > 0
                                      ? task.completedSubtaskCount /
                                          task.totalSubtaskCount
                                      : 0,
                                  minHeight: 4,
                                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                                  valueColor:
                                      AlwaysStoppedAnimation(categoryColor),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${task.completedSubtaskCount}/${task.totalSubtaskCount}',
                              style: TextStyle(
                                fontSize: 11,
                                color: textColor.withValues(alpha: 0.5),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                      // Inline subtask checkboxes — shown when expanded
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
                                  .map((s) => Map<String, dynamic>.from(s))
                                  .toList();
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
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDone ? categoryColor : Colors.transparent,
                                      border: Border.all(
                                        color: isDone
                                            ? categoryColor
                                            : Colors.grey.withValues(alpha: 0.4),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: isDone
                                        ? const Icon(Icons.check,
                                            size: 10, color: Colors.white)
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      subtask['title'] ?? '',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDone
                                            ? textColor.withValues(alpha: 0.4)
                                            : textColor.withValues(alpha: 0.75),
                                        decoration: isDone
                                            ? TextDecoration.lineThrough
                                            : null,
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
    );

    // N3: Swipe right → toggle complete
    final dismissibleCard = Dismissible(
      key: Key('dis_${task.id}_${task.startTime?.millisecondsSinceEpoch ?? 0}'),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        await _toggleComplete();
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              task.isCompleted
                  ? Icons.remove_done_rounded
                  : Icons.check_circle_rounded,
              color: Colors.green,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              task.isCompleted ? 'Reopen' : 'Complete',
              style: const TextStyle(
                  color: Colors.green, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
      ),
      // N4: Single tap → expand/collapse; double tap → edit
      child: GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        onDoubleTap: () =>
            Get.bottomSheet(TaskEntryDialog(existingTask: task), isScrollControlled: true),
        child: card,
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time label
        SizedBox(
          width: 56,
          child: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(
              task.startTime != null
                  ? DateFormat('h:mm\na').format(task.startTime!)
                  : DateFormat('h\na').format(widget.timeSlot),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
                height: 1.3,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        // Category-colored dot
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: categoryColor),
          ),
        ),
        const SizedBox(width: 6),
        // Card with drag support
        Expanded(
          child: LongPressDraggable<TimeTask>(
            data: task,
            feedback: Material(
              color: Colors.transparent,
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.72,
                child: Opacity(opacity: 0.85, child: card),
              ),
            ),
            childWhenDragging: Opacity(opacity: 0.3, child: card),
            child: dismissibleCard,
          ),
        ),
      ],
    );
  }
}
