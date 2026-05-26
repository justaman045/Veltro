import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/time_task.dart';
import '../providers/providers.dart';
import '../utils/app_colors.dart';

class StatsView extends ConsumerWidget {
  const StatsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTasksAsync = ref.watch(allTasksProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Productivity Stats', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(allTasksProvider),
          ),
        ],
      ),
      body: allTasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading stats: $e')),
        data: (tasks) => _StatsBody(tasks: tasks),
      ),
    );
  }
}

class _StatsBody extends StatelessWidget {
  final List<TimeTask> tasks;

  const _StatsBody({required this.tasks});

  int _computeBestStreak(List<TimeTask> tasks) {
    int best = 0;
    final recurring = tasks.where((t) => t.recurrence != RecurrenceType.none && t.completedDates != null).toList();
    for (final task in recurring) {
      int streak = 0;
      var checkDate = DateTime.now();
      checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day);
      while (true) {
        final done = task.completedDates!.any((d) =>
          d.year == checkDate.year && d.month == checkDate.month && d.day == checkDate.day);
        if (!done) break;
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
      if (streak > best) best = streak;
    }
    return best;
  }

  Map<String, int> _completionsPerDay(List<TimeTask> tasks) {
    final now = DateTime.now();
    final result = <String, int>{};
    for (var i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final label = DateFormat('E').format(day);
      result[label] = 0;
    }

    // Recurring completions
    for (final task in tasks) {
      if (task.completedDates == null) continue;
      for (final d in task.completedDates!) {
        final dayAgo = DateTime.now().difference(d).inDays;
        if (dayAgo >= 0 && dayAgo < 7) {
          final label = DateFormat('E').format(d);
          result[label] = (result[label] ?? 0) + 1;
        }
      }
    }

    return result;
  }

  Map<TaskCategory, int> _tasksByCategory(List<TimeTask> tasks) {
    final result = <TaskCategory, int>{};
    for (final cat in TaskCategory.values) { result[cat] = 0; }
    for (final t in tasks) { result[t.category] = (result[t.category] ?? 0) + 1; }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final totalTasks = tasks.length;
    final openTasks = tasks.where((t) => !t.isCompleted).length;
    final bestStreak = _computeBestStreak(tasks);
    final byDay = _completionsPerDay(tasks);
    final byCategory = _tasksByCategory(tasks);
    final maxDayCount = byDay.values.fold(0, (a, b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Overview cards
        Row(
          children: [
            _StatCard(label: 'All Tasks', value: '$totalTasks', color: context.gradientPrimary, icon: Icons.task_alt_rounded),
            const SizedBox(width: 12),
            _StatCard(label: 'Open', value: '$openTasks', color: context.gradientSecondary, icon: Icons.pending_actions_rounded),
            const SizedBox(width: 12),
            _StatCard(label: 'Best Streak', value: '$bestStreak', color: context.gradientTertiary, icon: Icons.local_fire_department_rounded),
          ],
        ),
        const SizedBox(height: 32),

        // Weekly activity bar chart
        Row(
          children: [
            Text('Last 7 Days', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            const Spacer(),
            Text('recurring only', style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.4))),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 180,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: BarChart(
            BarChartData(
              maxY: (maxDayCount + 1).toDouble().clamp(4, double.infinity),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(color: textColor.withValues(alpha: 0.08), strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final labels = byDay.keys.toList();
                      final idx = value.toInt();
                      if (idx < 0 || idx >= labels.length) return const SizedBox.shrink();
                      return Text(labels[idx], style: TextStyle(fontSize: 11, color: textColor.withValues(alpha: 0.5)));
                    },
                    reservedSize: 24,
                  ),
                ),
              ),
              barGroups: byDay.values.toList().asMap().entries.map((e) {
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value.toDouble(),
                      width: 16,
                      borderRadius: BorderRadius.circular(6),
                      gradient: LinearGradient(
                        colors: [context.gradientPrimary, context.gradientSecondary],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Category breakdown
        Text('By Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 16),
        if (totalTasks == 0)
          Center(child: Text('No tasks yet', style: TextStyle(color: textColor.withValues(alpha: 0.5))))
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                SizedBox(
                  height: 140,
                  width: 140,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 36,
                      sections: TaskCategory.values
                          .where((c) => (byCategory[c] ?? 0) > 0)
                          .map((c) => PieChartSectionData(
                                value: (byCategory[c] ?? 0).toDouble(),
                                color: TimeTask.categoryColors[c]!,
                                radius: 40,
                                title: '',
                              ))
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: TaskCategory.values.map((cat) {
                      final count = byCategory[cat] ?? 0;
                      final color = TimeTask.categoryColors[cat]!;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text(
                              cat.name[0].toUpperCase() + cat.name.substring(1),
                              style: TextStyle(fontSize: 13, color: textColor.withValues(alpha: 0.8)),
                            ),
                            const Spacer(),
                            Text('$count', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 32),

        // Priority breakdown
        Text('By Priority', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: TaskPriority.values.reversed.map((p) {
              final count = tasks.where((t) => t.priority == p).length;
              final color = TimeTask.priorityColors[p]!;
              final frac = totalTasks == 0 ? 0.0 : count / totalTasks;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: Text(p.name[0].toUpperCase() + p.name.substring(1),
                          style: TextStyle(fontSize: 13, color: textColor.withValues(alpha: 0.7))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: frac,
                          minHeight: 10,
                          backgroundColor: color.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 24,
                      child: Text('$count', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 10),
            Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
