import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/time_task.dart';
import '../providers/providers.dart';
import '../utils/animations.dart';
import 'task_card.dart';

class DayView extends ConsumerStatefulWidget {
  final List<TimeTask> tasks;
  final DateTime selectedDate;
  final ScrollController scrollController;

  const DayView({
    super.key,
    required this.tasks,
    required this.selectedDate,
    required this.scrollController,
  });

  @override
  ConsumerState<DayView> createState() => _DayViewState();
}

class _DayViewState extends ConsumerState<DayView> {
  static const double hourHeight = 72.0;
  static const double timeLabelWidth = 56.0;
  static const double minTaskHeight = 72.0;

  double _topForHour(int hour) => hour * hourHeight;
  double _topForTime(DateTime time) =>
      (time.hour + time.minute / 60.0 + time.second / 3600.0) * hourHeight;

  double _taskHeight(TimeTask task) {
    final diff = task.endTime != null
        ? task.endTime!.difference(task.startTime!).inMinutes / 60.0
        : 1.0;
    return (diff * hourHeight).clamp(minTaskHeight, double.infinity);
  }

  List<TimeTask> get _scheduledTasks =>
      widget.tasks.where((t) => t.startTime != null).toList();

  List<List<TimeTask>> _assignLanes(List<TimeTask> tasks) {
    final sorted = List<TimeTask>.from(tasks)
      ..sort((a, b) => a.startTime!.compareTo(b.startTime!));

    final lanes = <List<TimeTask>>[];
    for (final task in sorted) {
      final taskTop = _topForTime(task.startTime!);
      int? placed;
      for (int l = 0; l < lanes.length; l++) {
        final last = lanes[l].last;
        final lastBottom = _topForTime(last.startTime!) + _taskHeight(last);
        if (taskTop >= lastBottom) {
          placed = l;
          break;
        }
      }
      if (placed == null) {
        placed = lanes.length;
        lanes.add([]);
      }
      lanes[placed].add(task);
    }
    return lanes;
  }

  // ── Hour divider line ───────────────────────────────────────────
  Widget _buildHourLine(int hour, bool isDark) {
    return Positioned(
      top: _topForHour(hour),
      left: 0,
      right: 0,
      height: hourHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: timeLabelWidth,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                DateFormat('h a').format(DateTime(2024, 1, 1, hour)),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              height: 0.5,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.black.withValues(alpha: 0.07),
            ),
          ),
        ],
      ),
    );
  }

  // ── Drag target zone per hour ───────────────────────────────────
  Widget _buildDropZone(int hour, bool isDark) {
    return Positioned(
      top: _topForHour(hour),
      left: timeLabelWidth,
      width: MediaQuery.of(context).size.width - timeLabelWidth - 48,
      height: hourHeight,
      child: DragTarget<TimeTask>(
        onAcceptWithDetails: (details) async {
          final task = details.data;
          if (task.startTime == null) return;
          if (!mounted) return;
          final renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox == null) return;
          final localPos = renderBox.globalToLocal(details.offset);
          final relativeY = (localPos.dy - _topForHour(hour)) / hourHeight;
          final minute = (relativeY * 4).floor() * 15;
          final newStart = DateTime(
            task.startTime!.year,
            task.startTime!.month,
            task.startTime!.day,
            hour,
            minute.clamp(0, 59),
          );
          final updatedTask = TimeTask()
            ..id = task.id
            ..title = task.title
            ..notes = task.notes
            ..startTime = newStart
            ..endTime = task.endTime
            ..isCompleted = task.isCompleted
            ..recurrence = task.recurrence
            ..completedDates = task.completedDates?.toList()
            ..excludedDates = task.excludedDates?.toList()
            ..type = task.type
            ..category = task.category
            ..priority = task.priority
            ..subtasks = task.subtasks?.map((s) => Map<String, dynamic>.from(s)).toList();
          await ref.read(dbServiceProvider).saveTimeTask(updatedTask);
        },
        builder: (context, candidates, rejected) {
          final highlighted = candidates.isNotEmpty;
          return AnimatedContainer(
            duration: kAnimNormal,
            curve: Curves.easeInOut,
            decoration: highlighted
                ? BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                  )
                : const BoxDecoration(),
          );
        },
      ),
    );
  }

  // ── Task card position ─────────────────────────────────────────
  Widget _buildTaskCard(TimeTask task, int lane, int totalLanes) {
    final availableWidth = MediaQuery.of(context).size.width - timeLabelWidth - 48;
    final laneWidth = availableWidth / totalLanes;
    final top = _topForTime(task.startTime!);
    final height = _taskHeight(task);

    return Positioned(
      top: top,
      left: timeLabelWidth + lane * laneWidth + 2,
      width: laneWidth - 4,
      child: TaskCard(task: task, height: height),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheduled = _scheduledTasks;
    final lanes = _assignLanes(scheduled);

    return SingleChildScrollView(
      controller: widget.scrollController,
      child: SizedBox(
        height: 24 * hourHeight,
        child: Stack(
          children: [
            // Grid: hour lines
            for (int h = 0; h < 24; h++)
              _buildHourLine(h, isDark),
            // Drop zones
            for (int h = 0; h < 24; h++)
              _buildDropZone(h, isDark),
            // Task cards
            for (int l = 0; l < lanes.length; l++)
              for (final task in lanes[l])
                _buildTaskCard(task, l, lanes.length),
          ],
        ),
      ),
    );
  }
}
