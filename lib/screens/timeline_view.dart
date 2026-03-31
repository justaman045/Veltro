import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/time_task.dart';
import '../providers/providers.dart';
import 'settings_view.dart';
import '../widgets/timeline_item.dart';

class TimelineView extends ConsumerStatefulWidget {
  const TimelineView({super.key});

  @override
  ConsumerState<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends ConsumerState<TimelineView> {
  late DateTime _selectedDate;
  // Use a very high initial index to allow near-infinite swiping in both directions
  final int _initialPageIndex = 10000;
  late final PageController _pageController;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _pageController = PageController(initialPage: _initialPageIndex);
    
    // Jump to 2 hours before the current time (or 0 if earlier than 2 AM)
    int targetHour = now.hour - 2;
    if (targetHour < 0) targetHour = 0;
    
    _scrollController = ScrollController(initialScrollOffset: targetHour * 84.0); // 84px per empty hour slot
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
           _selectedDate.month == now.month &&
           _selectedDate.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final timelineAsync = ref.watch(timelineTasksProvider(_selectedDate));
    final currentTasks = timelineAsync.valueOrNull ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top action bar
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isToday ? "Today's tasks" : "Tasks",
                style: const TextStyle(
                  fontSize: 34, // Large iOS Header
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.0,
                ),
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
              )
            ],
          ),
        ),
        
        // Date Header - Horizontally swipeable PageView
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: SizedBox(
            height: 80, // Fixed height to contain the page view
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (index) {
                      final dayOffset = index - _initialPageIndex;
                      final now = DateTime.now();
                      setState(() {
                        _selectedDate = DateTime(now.year, now.month, now.day).add(Duration(days: dayOffset));
                      });
                    },
                    itemBuilder: (context, index) {
                      // Calculate the date for this specific page index
                      final dayOffset = index - _initialPageIndex;
                      final now = DateTime.now();
                      final pageDate = DateTime(now.year, now.month, now.day).add(Duration(days: dayOffset));
                      
                      // Optimization: only read tasks if it's the currently selected page snippet (though riverpod caches this)
                      // Here we format the date text specific to this page index
                      final isTodayPage = pageDate.year == now.year && pageDate.month == now.month && pageDate.day == now.day;
                      
                      return GestureDetector(
                        onTap: () {
                          if (dayOffset != 0) {
                            _pageController.animateToPage(
                              _initialPageIndex,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        child: Container(
                          color: Colors.transparent, // Ensures the whole area is tappable
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                DateFormat('MMMM dd').format(pageDate),
                                style: const TextStyle(
                                  fontSize: 36, // Massive date anchor
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                // Tasks count updates when state actually changes and provider triggers a rebuild
                                pageDate == _selectedDate ? '${currentTasks.length} tasks ${isTodayPage ? 'today' : 'on this day'}' : 'Swipe to view tasks',
                                style: TextStyle(
                                  fontSize: 16, 
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), 
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      // Jump the page view to the selected date's absolute offset
                      final now = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
                      final diffDays = date.difference(now).inDays;
                      _pageController.animateToPage(
                        _initialPageIndex + diffDays,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.15), // Soft glowing tertiary
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.2),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(Icons.calendar_month, color: Theme.of(context).colorScheme.tertiary),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        Expanded(
          child: timelineAsync.when(
            data: (tasks) {
              if (tasks.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.event_available_rounded, 
                          size: 64, 
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.5)
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Your day is clear',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isToday ? 'No events scheduled for today.' : 'Nothing on ${DateFormat('MMM dd').format(_selectedDate)}.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ).animate().fade(duration: 400.ms).scale(begin: const Offset(0.9, 0.9), delay: 100.ms),
                );
              }
              
              return Builder(
                builder: (context) {
                  // Deduplicate tasks by ID just in case overlapping streams double-emit them
                  final uniqueTasks = <String, TimeTask>{};
                  for (final task in tasks) {
                    uniqueTasks[task.id] = task;
                  }
                  
                  // Generate 24 continuous hourly slots for the selected date
                  final timeSlots = List.generate(24, (i) => DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, i));
                  
                  // Map tasks into their respective 1-hour buckets
                  final Map<DateTime, List<TimeTask>> groupedTasks = {};
                  for (final slot in timeSlots) {
                    groupedTasks[slot] = uniqueTasks.values.where((t) {
                      if (t.startTime == null) return false;
                      
                      // 1. Exact Date Match
                      final isExactMatch = t.startTime!.hour == slot.hour &&
                                           t.startTime!.day == slot.day &&
                                           t.startTime!.month == slot.month &&
                                           t.startTime!.year == slot.year;
                                           
                      if (isExactMatch) return true;
                      
                      // 2. Overdue Past Pending Tasks
                      // If the slot belongs to TODAY, allow overdue tasks to slot into their respective hour natively
                      final now = DateTime.now();
                      final isTodaySlot = slot.year == now.year && slot.month == now.month && slot.day == now.day;
                      
                      if (isTodaySlot) {
                        final isPastPending = t.startTime!.isBefore(DateTime(now.year, now.month, now.day)) && 
                                              !t.isCompleted && 
                                              t.recurrence == RecurrenceType.none;
                                              
                        if (isPastPending && t.startTime!.hour == slot.hour) {
                          return true;
                        }
                      }
                      
                      return false;
                    }).toList();
                    
                    // Chronological sort within the hour
                    groupedTasks[slot]!.sort((a, b) => a.startTime!.compareTo(b.startTime!));
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      await Future.delayed(const Duration(milliseconds: 500));
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(bottom: 100), // Space for FAB
                      itemCount: timeSlots.length,
                      itemBuilder: (context, index) {
                        final timeSlot = timeSlots[index];
                        final tasksForSlot = groupedTasks[timeSlot]!;

                        return DragTarget<TimeTask>(
                          onAcceptWithDetails: (details) {
                            final db = ref.read(dbServiceProvider);
                            final droppedTask = details.data;
                            
                            if (droppedTask.startTime != null) {
                              final newStart = DateTime(
                                droppedTask.startTime!.year,
                                droppedTask.startTime!.month,
                                droppedTask.startTime!.day,
                                timeSlot.hour,
                                timeSlot.minute
                              );
                              droppedTask.startTime = newStart;
                              db.saveTimeTask(droppedTask);
                            }
                          },
                          builder: (context, candidateData, rejectedData) {
                            return Container(
                              // Highlight the row slightly if a task is hovering over it
                              color: candidateData.isNotEmpty 
                                ? Theme.of(context).primaryColor.withValues(alpha: 0.1) 
                                : Colors.transparent,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                child: TimelineItem(
                                  tasks: tasksForSlot,
                                  timeSlot: timeSlot,
                                  isFirst: index == 0,
                                  isLast: index == timeSlots.length - 1,
                                  index: index,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                }
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
          ),
        ),
      ],
    );
  }
}
