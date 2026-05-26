import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/time_task.dart';
import '../providers/providers.dart';
import '../utils/animations.dart';
import 'settings_view.dart';
import '../widgets/timeline_item.dart';
import '../widgets/ai_briefing_card.dart';

class TimelineView extends ConsumerStatefulWidget {
  const TimelineView({super.key});

  @override
  ConsumerState<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends ConsumerState<TimelineView> {
  late DateTime _selectedDate;
  final int _initialPageIndex = 10000;
  late final PageController _pageController;
  late final ScrollController _scrollController;
  final List<GlobalKey> _slotKeys = List.generate(24, (_) => GlobalKey());
  bool _searchActive = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();

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
    _searchController.dispose();
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
    // Jump to a date selected from the Calendar tab.
    // ref.watch guarantees we see the value the moment this widget mounts —
    // no listener-registration race like ref.listen has.
    final jumpDate = ref.watch(calendarJumpDateProvider);
    if (jumpDate != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
        final diff = jumpDate.difference(today).inDays;
        _pageController.animateToPage(
          _initialPageIndex + diff,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        ref.read(calendarJumpDateProvider.notifier).state = null;
      });
    }

    final timelineAsync = ref.watch(timelineTasksProvider(_selectedDate));
    final currentTasks = timelineAsync.valueOrNull ?? [];

    final bool inSearchMode = _searchActive && _searchQuery.isNotEmpty;
    final allTasksAsync = inSearchMode ? ref.watch(allTasksProvider) : null;

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
                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -1.0),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(_searchActive ? Icons.search_off_rounded : Icons.search_rounded),
                    onPressed: () {
                      setState(() {
                        _searchActive = !_searchActive;
                        if (!_searchActive) {
                          _searchQuery = '';
                          _searchController.clear();
                        }
                      });
                    },
                  ),
                  GestureDetector(
                    onTap: () => Get.to(() => const SettingsView()),
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
            ],
          ),
        ),
        AnimatedSize(
          duration: animDuration(context, ms: 250),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: _searchActive
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: Colors.grey.shade400, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            onChanged: (v) => setState(() => _searchQuery = v),
                            decoration: InputDecoration(
                              hintText: 'Search tasks...',
                              border: InputBorder.none,
                              isDense: true,
                              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        
        AnimatedCrossFade(
          firstChild: Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Header - Horizontally swipeable PageView
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: SizedBox(
                    height: 80,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            physics: const BouncingScrollPhysics(),
                            onPageChanged: (index) {
                              if (!mounted) return;
                              final dayOffset = index - _initialPageIndex;
                              final now = DateTime.now();
                              setState(() {
                                _selectedDate = DateTime(now.year, now.month, now.day).add(Duration(days: dayOffset));
                              });
                            },
                            itemBuilder: (context, index) {
                              final dayOffset = index - _initialPageIndex;
                              final now = DateTime.now();
                              final pageDate = DateTime(now.year, now.month, now.day).add(Duration(days: dayOffset));
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
                                  color: Colors.transparent,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        DateFormat('MMMM dd').format(pageDate),
                                        style: const TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
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
                              if (!mounted) return;
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
                              color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.15),
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
                const AiBriefingCard(),
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
                                  color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
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
                                style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                              ),
                            ],
                          ).animate().fade(duration: 400.ms).scale(begin: const Offset(0.9, 0.9), delay: 100.ms),
                        );
                      }
                      return Builder(
                        builder: (context) {
                          final uniqueTasks = <String, TimeTask>{};
                          for (final task in tasks) {
                            uniqueTasks[task.id] = task;
                          }
                          final timeSlots = List.generate(24, (i) => DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, i));
                          final Map<DateTime, List<TimeTask>> groupedTasks = {};
                          for (final slot in timeSlots) {
                            groupedTasks[slot] = uniqueTasks.values.where((t) {
                              if (t.startTime == null) return false;
                              final isExactMatch = t.startTime!.hour == slot.hour &&
                                                   t.startTime!.day == slot.day &&
                                                   t.startTime!.month == slot.month &&
                                                   t.startTime!.year == slot.year;
                              if (isExactMatch) return true;
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
                            groupedTasks[slot]!.sort((a, b) {
                              if (a.startTime == null && b.startTime == null) return 0;
                              if (a.startTime == null) return -1;
                              if (b.startTime == null) return 1;
                              return a.startTime!.compareTo(b.startTime!);
                            });
                          }
                          return RefreshIndicator(
                            onRefresh: () async {
                              await Future.delayed(const Duration(milliseconds: 500));
                            },
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.only(bottom: 100),
                              itemCount: timeSlots.length,
                              itemBuilder: (context, index) {
                                final timeSlot = timeSlots[index];
                                final tasksForSlot = groupedTasks[timeSlot]!;
                                return DragTarget<TimeTask>(
                                  onAcceptWithDetails: (details) async {
                                    if (!mounted) return;
                                    final db = ref.read(dbServiceProvider);
                                    final droppedTask = details.data;
                                    if (droppedTask.startTime != null) {
                                      final box = _slotKeys[index].currentContext?.findRenderObject() as RenderBox?;
                                      int minute = timeSlot.minute;
                                      if (box != null && box.size.height > 0) {
                                        final localPos = box.globalToLocal(details.offset);
                                        final relativeY = localPos.dy / box.size.height;
                                        minute = (relativeY * 4).floor() * 15;
                                        minute = minute.clamp(0, 59);
                                      }
                                      final newStart = DateTime(
                                        droppedTask.startTime!.year,
                                        droppedTask.startTime!.month,
                                        droppedTask.startTime!.day,
                                        timeSlot.hour,
                                        minute,
                                      );
                                      final updatedTask = TimeTask()
                                        ..id = droppedTask.id
                                        ..title = droppedTask.title
                                        ..notes = droppedTask.notes
                                        ..startTime = newStart
                                        ..endTime = droppedTask.endTime
                                        ..isCompleted = droppedTask.isCompleted
                                        ..recurrence = droppedTask.recurrence
                                        ..completedDates = droppedTask.completedDates?.toList()
                                        ..excludedDates = droppedTask.excludedDates?.toList()
                                        ..type = droppedTask.type
                                        ..category = droppedTask.category;
                                      await db.saveTimeTask(updatedTask);
                                    }
                                  },
                                  builder: (context, candidateData, rejectedData) {
                                    return Container(
                                      key: _slotKeys[index],
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
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.redAccent),
                          const SizedBox(height: 16),
                          Text('Database Schema Mismatch', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
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
            ),
          ),
          secondChild: Expanded(
            child: allTasksAsync!.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Search error: $e')),
              data: (allTasks) {
                final q = _searchQuery.toLowerCase();
                final matches = allTasks
                    .where((t) =>
                        t.title.toLowerCase().contains(q) ||
                        t.notes.toLowerCase().contains(q))
                    .toList()
                  ..sort((a, b) {
                    if (a.startTime == null && b.startTime == null) return 0;
                    if (a.startTime == null) return 1;
                    if (b.startTime == null) return -1;
                    return a.startTime!.compareTo(b.startTime!);
                  });

                if (matches.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 56, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('No tasks found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                        const SizedBox(height: 6),
                        Text('No tasks match "$_searchQuery"', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final task = matches[index];
                    final categoryColor = TimeTask.categoryColors[task.category] ?? Colors.grey;
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    final dateLabel = task.startTime != null
                        ? DateFormat('EEE, MMM d').format(task.startTime!)
                        : 'Todo (unscheduled)';
                    final timeLabel = task.startTime != null
                        ? DateFormat.jm().format(task.startTime!)
                        : null;

                    return GestureDetector(
                      onTap: () {
                        if (task.startTime != null) {
                          final taskDate = DateTime(task.startTime!.year, task.startTime!.month, task.startTime!.day);
                          final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
                          final diff = taskDate.difference(today).inDays;
                          _pageController.animateToPage(
                            _initialPageIndex + diff,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                        setState(() {
                          _searchActive = false;
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border(left: BorderSide(color: categoryColor, width: 3)),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.title,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.onSurface,
                                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today_rounded, size: 11, color: Colors.grey.shade400),
                                        const SizedBox(width: 4),
                                        Text(dateLabel, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                        if (timeLabel != null) ...[
                                          const SizedBox(width: 8),
                                          Icon(Icons.access_time_rounded, size: 11, color: Colors.grey.shade400),
                                          const SizedBox(width: 4),
                                          Text(timeLabel, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: categoryColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  task.category.name[0].toUpperCase() + task.category.name.substring(1),
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: categoryColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          crossFadeState: inSearchMode ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: animDuration(context, ms: 300),
          sizeCurve: Curves.easeOut,
        ),

        // Date Header - Horizontally swipeable PageView (hidden during search)
        if (!inSearchMode)
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
                      if (!mounted) return;
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
                      if (!mounted) return;
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
        
        if (!inSearchMode) const AiBriefingCard(),
        if (!inSearchMode) const SizedBox(height: 16),
        if (!inSearchMode)
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
                    groupedTasks[slot]!.sort((a, b) {
                      if (a.startTime == null && b.startTime == null) return 0;
                      if (a.startTime == null) return -1;
                      if (b.startTime == null) return 1;
                      return a.startTime!.compareTo(b.startTime!);
                    });
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
                          onAcceptWithDetails: (details) async {
                            if (!mounted) return;
                            final db = ref.read(dbServiceProvider);
                            final droppedTask = details.data;
                            
                            if (droppedTask.startTime != null) {
                              final box = _slotKeys[index].currentContext?.findRenderObject() as RenderBox?;
                              int minute = timeSlot.minute;
                              if (box != null && box.size.height > 0) {
                                final localPos = box.globalToLocal(details.offset);
                                final relativeY = localPos.dy / box.size.height;
                                minute = (relativeY * 4).floor() * 15;
                                minute = minute.clamp(0, 59);
                              }
                              final newStart = DateTime(
                                droppedTask.startTime!.year,
                                droppedTask.startTime!.month,
                                droppedTask.startTime!.day,
                                timeSlot.hour,
                                minute,
                              );
                              final updatedTask = TimeTask()
                                ..id = droppedTask.id
                                ..title = droppedTask.title
                                ..notes = droppedTask.notes
                                ..startTime = newStart
                                ..endTime = droppedTask.endTime
                                ..isCompleted = droppedTask.isCompleted
                                ..recurrence = droppedTask.recurrence
                                ..completedDates = droppedTask.completedDates?.toList()
                                ..excludedDates = droppedTask.excludedDates?.toList()
                                ..type = droppedTask.type
                                ..category = droppedTask.category;
                              await db.saveTimeTask(updatedTask);
                            }
                          },
                          builder: (context, candidateData, rejectedData) {
                            return Container(
                              key: _slotKeys[index],
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
                  Text('Database Schema Mismatch', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
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
