import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/time_task.dart';
import '../providers/providers.dart';

class CalendarView extends ConsumerStatefulWidget {
  final VoidCallback onSwitchToTimeline;

  const CalendarView({super.key, required this.onSwitchToTimeline});

  @override
  ConsumerState<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends ConsumerState<CalendarView> {
  late DateTime _displayMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayMonth = DateTime(now.year, now.month);
  }

  bool _taskOccursOnDay(TimeTask task, DateTime day) {
    if (task.startTime == null) return false;

    switch (task.recurrence) {
      case RecurrenceType.none:
        return task.startTime!.year == day.year &&
            task.startTime!.month == day.month &&
            task.startTime!.day == day.day;
      case RecurrenceType.daily:
        return !day.isBefore(
            DateTime(task.startTime!.year, task.startTime!.month, task.startTime!.day));
      case RecurrenceType.weekly:
        return task.startTime!.weekday == day.weekday &&
            !day.isBefore(DateTime(
                task.startTime!.year, task.startTime!.month, task.startTime!.day));
      case RecurrenceType.monthly:
        return task.startTime!.day == day.day &&
            !day.isBefore(DateTime(
                task.startTime!.year, task.startTime!.month, task.startTime!.day));
      case RecurrenceType.weekdays:
        return day.weekday <= 5 &&
            !day.isBefore(DateTime(
                task.startTime!.year, task.startTime!.month, task.startTime!.day));
    }
  }

  void _jumpToDay(DateTime day) {
    ref.read(calendarJumpDateProvider.notifier).state = day;
    widget.onSwitchToTimeline();
  }

  @override
  Widget build(BuildContext context) {
    final allTasksAsync = ref.watch(allTasksProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Row(
            children: [
              Text(
                'Calendar',
                style: const TextStyle(
                    fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -1.0),
              ),
            ],
          ),
        ),

        // Month navigation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              IconButton(
                onPressed: () => setState(() =>
                    _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1)),
                icon: const Icon(Icons.chevron_left_rounded),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat('MMMM yyyy').format(_displayMonth),
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.5),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() =>
                    _displayMonth = DateTime(today.year, today.month)),
                child: const Text('Today'),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => setState(() =>
                    _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1)),
                icon: const Icon(Icons.chevron_right_rounded),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Day-of-week header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textColor.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),

        const SizedBox(height: 8),

        // Calendar grid
        Expanded(
          child: allTasksAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (tasks) {
              final firstDay = _displayMonth;
              // Monday = 1, Sunday = 7
              final startWeekday = firstDay.weekday; // 1..7
              final daysInMonth =
                  DateTime(_displayMonth.year, _displayMonth.month + 1, 0).day;
              // Cells before the 1st (empty)
              final leadingEmpty = startWeekday - 1;
              final totalCells = leadingEmpty + daysInMonth;
              final rows = (totalCells / 7).ceil();

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: List.generate(rows, (rowIndex) {
                    return Expanded(
                      child: Row(
                        children: List.generate(7, (colIndex) {
                          final cellIndex = rowIndex * 7 + colIndex;
                          final dayNumber = cellIndex - leadingEmpty + 1;
                          if (dayNumber < 1 || dayNumber > daysInMonth) {
                            return const Expanded(child: SizedBox.shrink());
                          }
                          final day = DateTime(
                              _displayMonth.year, _displayMonth.month, dayNumber);
                          final isToday = day == todayNorm;
                          final isPast = day.isBefore(todayNorm);

                          // Tasks for this day
                          final dayTasks = tasks
                              .where((t) => _taskOccursOnDay(t, day))
                              .toList();
                          final dotColors = dayTasks
                              .take(3)
                              .map((t) =>
                                  TimeTask.categoryColors[t.category] ??
                                  Colors.grey)
                              .toList();
                          final extra = dayTasks.length > 3 ? dayTasks.length - 3 : 0;

                          return Expanded(
                            child: GestureDetector(
                              onTap: () => _jumpToDay(day),
                              child: Container(
                                margin: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: isToday
                                      ? Theme.of(context).colorScheme.primary
                                      : isDark
                                          ? Colors.white.withValues(alpha: 0.03)
                                          : Colors.black.withValues(alpha: 0.025),
                                  borderRadius: BorderRadius.circular(12),
                                  border: isToday
                                      ? null
                                      : Border.all(
                                          color: textColor.withValues(alpha: 0.06),
                                          width: 0.5),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '$dayNumber',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isToday
                                            ? Colors.white
                                            : isPast
                                                ? textColor.withValues(alpha: 0.35)
                                                : textColor.withValues(alpha: 0.85),
                                      ),
                                    ),
                                    if (dotColors.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          ...dotColors.map((c) => Container(
                                                width: 5,
                                                height: 5,
                                                margin: const EdgeInsets.symmetric(
                                                    horizontal: 1),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: isToday
                                                      ? Colors.white
                                                          .withValues(alpha: 0.8)
                                                      : c,
                                                ),
                                              )),
                                          if (extra > 0)
                                            Text(
                                              '+$extra',
                                              style: TextStyle(
                                                fontSize: 8,
                                                color: isToday
                                                    ? Colors.white
                                                        .withValues(alpha: 0.7)
                                                    : textColor
                                                        .withValues(alpha: 0.4),
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  }),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 100),
      ],
    );
  }
}
