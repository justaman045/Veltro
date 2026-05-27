import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/time_task.dart';
import '../providers/providers.dart';
import '../utils/app_colors.dart';
import '../utils/nlp_parser.dart';

class TaskEntryDialog extends ConsumerStatefulWidget {
  final TimeTask? existingTask;
  // When true, treat the existingTask as a template (don't copy ID → new task)
  final bool isFromTemplate;

  const TaskEntryDialog({super.key, this.existingTask, this.isFromTemplate = false});

  @override
  ConsumerState<TaskEntryDialog> createState() => _TaskEntryDialogState();
}

class _TaskEntryDialogState extends ConsumerState<TaskEntryDialog> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  TaskType _type = TaskType.task;
  TaskCategory _category = TaskCategory.personal;
  DateTime? _selectedDate;
  TimeOfDay? _timeOfDay;
  TimeOfDay? _endTimeOfDay;
  RecurrenceType _recurrence = RecurrenceType.none;
  TaskPriority _priority = TaskPriority.medium;
  List<Map<String, dynamic>> _subtasks = [];
  final _subtaskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final t = widget.existingTask;
    if (t != null) {
      _titleController.text = t.title;
      _notesController.text = t.notes;
      _type = t.type;
      _category = t.category;
      _recurrence = t.recurrence;
      _priority = t.priority;
      _subtasks = t.subtasks?.map((s) => Map<String, dynamic>.from(s)).toList() ?? [];
      if (t.startTime != null) {
        _selectedDate = DateTime(t.startTime!.year, t.startTime!.month, t.startTime!.day);
        _timeOfDay = TimeOfDay.fromDateTime(t.startTime!);
      }
      if (t.endTime != null) {
        _endTimeOfDay = TimeOfDay.fromDateTime(t.endTime!);
      }
    } else {
      final now = DateTime.now();
      _selectedDate = DateTime(now.year, now.month, now.day);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  void _tryNlpParse() {
    ({DateTime? date, TimeOfDay? time}) result;
    try {
      result = NlpParser.parse(_titleController.text);
    } catch (_) {
      Get.snackbar('Couldn\'t parse that', 'Try "Call dentist tomorrow at 3pm"',
          snackPosition: SnackPosition.TOP, backgroundColor: Colors.black87,
          colorText: Colors.white, margin: const EdgeInsets.all(16),
          borderRadius: 12, duration: const Duration(seconds: 2));
      return;
    }
    if (result.date != null || result.time != null) {
      setState(() {
        if (result.date != null) _selectedDate = result.date;
        if (result.time != null) _timeOfDay = result.time;
      });
      Get.snackbar(
        'Parsed!',
        [
          if (result.date != null) DateFormat('MMM d').format(result.date!),
          if (result.time != null) result.time!.format(context),
        ].join(' at '),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 2),
        icon: const Icon(Icons.auto_awesome, color: Colors.amberAccent),
      );
    } else {
      Get.snackbar(
        'Nothing Found',
        'Try typing "Call dentist tomorrow at 3pm"',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> _tryAiParse() async {
    final text = _titleController.text.trim();
    if (text.isEmpty) {
      Get.snackbar('Empty Title', 'Type a task description first.',
          snackPosition: SnackPosition.TOP, backgroundColor: Colors.black87,
          colorText: Colors.white, margin: const EdgeInsets.all(16),
          borderRadius: 12, duration: const Duration(seconds: 2));
      return;
    }
    final isPro = ref.read(subscriptionServiceProvider).isPro;
    final aiUsage = ref.read(aiUsageCountProvider.notifier).state;
    if (!isPro && aiUsage >= 3) {
      Get.snackbar('AI Limit Reached', 'Upgrade to Pro for unlimited AI suggestions.',
          snackPosition: SnackPosition.TOP, backgroundColor: Colors.black87,
          colorText: Colors.white, margin: const EdgeInsets.all(16),
          borderRadius: 12, duration: const Duration(seconds: 2));
      return;
    }

    Get.snackbar('AI Analyzing...', 'Detecting task details from your title.',
        snackPosition: SnackPosition.TOP, backgroundColor: Colors.black87,
        colorText: Colors.white, margin: const EdgeInsets.all(16),
        borderRadius: 12, duration: const Duration(seconds: 1));

    try {
      final ai = ref.read(aiServiceProvider);
      final result = await ai.parseTaskFromText(text);

      if (!mounted) return;

      if (!isPro) {
        ref.read(aiUsageCountProvider.notifier).state++;
      }

      setState(() {
        if (result['title'] != null) {
          _titleController.text = result['title'] as String;
        }
        final category = result['category']?.toString();
        if (category != null) {
          _category = TaskCategory.values.firstWhere(
            (c) => c.name == category,
            orElse: () => TaskCategory.other,
          );
        }
        final priority = result['priority']?.toString();
        if (priority != null) {
          _priority = TaskPriority.values.firstWhere(
            (p) => p.name == priority,
            orElse: () => TaskPriority.medium,
          );
        }
        final recurrence = result['recurrence']?.toString();
        if (recurrence != null) {
          _recurrence = RecurrenceType.values.firstWhere(
            (r) => r.name == recurrence,
            orElse: () => RecurrenceType.none,
          );
        }
        if (result['notes'] != null && (result['notes'] as String).isNotEmpty) {
          _notesController.text = result['notes'] as String;
        }
        if (result['hasDate'] == true && result['date'] != null) {
          _selectedDate = DateTime.tryParse(result['date'] as String);
        }
        if (result['hasTime'] == true && result['time'] != null) {
          final parts = (result['time'] as String).split(':');
          if (parts.length == 2) {
            final hour = int.tryParse(parts[0]) ?? 0;
            final minute = int.tryParse(parts[1]) ?? 0;
            _timeOfDay = TimeOfDay(hour: hour, minute: minute);
          }
        }
      });

      final nlpResult = NlpParser.parse(text);
      if (nlpResult.date != null || nlpResult.time != null) {
        setState(() {
          if (nlpResult.date != null) _selectedDate = nlpResult.date;
          if (nlpResult.time != null) _timeOfDay = nlpResult.time;
        });
      }

      Get.snackbar('AI Parsed!', 'Category, priority, and schedule detected.',
          snackPosition: SnackPosition.TOP, backgroundColor: Colors.black87,
          colorText: Colors.white, margin: const EdgeInsets.all(16),
          borderRadius: 12, duration: const Duration(seconds: 2),
          icon: const Icon(Icons.auto_awesome, color: Colors.amberAccent));
    } catch (e) {
      if (mounted) {
        Get.snackbar('AI Parse Failed', e.toString().replaceAll('Exception: ', ''),
            snackPosition: SnackPosition.TOP, backgroundColor: Colors.black87,
            colorText: Colors.white, margin: const EdgeInsets.all(16),
            borderRadius: 12, duration: const Duration(seconds: 2));
      }
    }
  }

  void _addSubtask() {
    final title = _subtaskController.text.trim();
    if (title.isEmpty) return;
    setState(() {
      _subtasks.add({'title': title, 'done': false});
      _subtaskController.clear();
    });
  }

  void _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null && mounted) setState(() => _selectedDate = date);
  }

  void _pickTime() async {
    final time = await showTimePicker(context: context, initialTime: _timeOfDay ?? TimeOfDay.now());
    if (time != null && mounted) setState(() => _timeOfDay = time);
  }

  void _pickEndTime() async {
    final initial = _endTimeOfDay ??
        (_timeOfDay != null
            ? TimeOfDay(hour: (_timeOfDay!.hour + 1) % 24, minute: _timeOfDay!.minute)
            : TimeOfDay.now());
    final time = await showTimePicker(context: context, initialTime: initial);
    if (time != null && mounted) setState(() => _endTimeOfDay = time);
  }

  Future<String?> _showRecurringOverrideDialog(String actionDescription) {
    return Get.dialog<String>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Recurring Task'),
        content: Text('Do you want to apply this $actionDescription to this event only, or to all events in the series?'),
        actions: [
          TextButton(onPressed: () => Get.back(result: 'single'), child: const Text('This event only')),
          TextButton(onPressed: () => Get.back(result: 'all'), child: const Text('All events in series')),
        ],
      ),
    );
  }

  DateTime? _getFinalStartTime() {
    if (_timeOfDay != null && _selectedDate != null) {
      return DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _timeOfDay!.hour, _timeOfDay!.minute);
    }
    return null;
  }

  DateTime? _getFinalEndTime() {
    if (_endTimeOfDay != null && _selectedDate != null) {
      return DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _endTimeOfDay!.hour, _endTimeOfDay!.minute);
    }
    return null;
  }

  void _save() async {
    if (_titleController.text.isEmpty) return;
    if (_timeOfDay != null && _endTimeOfDay != null) {
      final s = _timeOfDay!.hour * 60 + _timeOfDay!.minute;
      final e = _endTimeOfDay!.hour * 60 + _endTimeOfDay!.minute;
      if (e <= s) {
        Get.snackbar('Invalid Time', 'End time must be after start time.',
            snackPosition: SnackPosition.TOP, backgroundColor: Colors.black87,
            colorText: Colors.white, margin: const EdgeInsets.all(16),
            borderRadius: 12, duration: const Duration(seconds: 2));
        return;
      }
    }
    final db = ref.read(dbServiceProvider);

    if (!widget.isFromTemplate && widget.existingTask != null && widget.existingTask!.recurrence != RecurrenceType.none) {
      final result = await _showRecurringOverrideDialog('edit');
      if (result == null) return;

      if (result == 'single') {
        final originalTask = await db.getTask(widget.existingTask!.id);
        if (originalTask != null) {
          final dates = originalTask.excludedDates?.toList() ?? [];
          final targetDate = widget.existingTask!.startTime ?? DateTime.now();
          final alreadyExcluded = dates.any((d) => d.year == targetDate.year && d.month == targetDate.month && d.day == targetDate.day);
          if (!alreadyExcluded) {
            dates.add(DateTime(targetDate.year, targetDate.month, targetDate.day));
            originalTask.excludedDates = dates;
            await db.saveTimeTask(originalTask);
          }
        }

        final newTask = TimeTask()
          ..title = _titleController.text
          ..notes = _notesController.text
          ..type = _type
          ..category = _category
          ..startTime = _getFinalStartTime()
          ..endTime = _getFinalEndTime()
          ..recurrence = RecurrenceType.none
          ..priority = _priority
          ..subtasks = _subtasks.isEmpty ? null : List.from(_subtasks)
          ..completedDates = widget.existingTask?.completedDates?.toList()
          ..excludedDates = widget.existingTask?.excludedDates?.toList()
          ..isCompleted = widget.existingTask?.isCompleted ?? false;

        await db.saveTimeTask(newTask);
        if (mounted) Navigator.of(context).pop();
        return;
      }
    }

    final task = (widget.isFromTemplate || widget.existingTask == null) ? TimeTask() : widget.existingTask!;
    task
      ..title = _titleController.text
      ..notes = _notesController.text
      ..type = _type
      ..category = _category
      ..startTime = _getFinalStartTime()
      ..endTime = _getFinalEndTime()
      ..recurrence = _recurrence
      ..priority = _priority
      ..subtasks = _subtasks.isEmpty ? null : List.from(_subtasks)
      ..isCompleted = widget.existingTask?.isCompleted ?? false;

    await db.saveTimeTask(task);
    if (mounted) Navigator.of(context).pop();
  }

  void _saveAsTemplate() async {
    if (_titleController.text.isEmpty) return;
    final db = ref.read(dbServiceProvider);
    final template = TimeTask()
      ..title = _titleController.text
      ..notes = _notesController.text
      ..type = _type
      ..category = _category
      ..recurrence = _recurrence
      ..priority = _priority
      ..startTime = _getFinalStartTime()
      ..subtasks = _subtasks.isEmpty ? null : List.from(_subtasks);
    await db.saveTemplate(template);
    Get.snackbar(
      'Template Saved',
      '"${template.title}" saved as a template.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
      icon: const Icon(Icons.content_copy_rounded, color: Colors.amberAccent),
    );
  }

  void _delete() async {
    final db = ref.read(dbServiceProvider);
    if (widget.existingTask != null && !widget.isFromTemplate) {
      if (widget.existingTask!.recurrence != RecurrenceType.none) {
        final result = await _showRecurringOverrideDialog('deletion');
        if (result == null) return;
        if (mounted) Navigator.of(context).pop();
        if (result == 'single') {
          final originalTask = await db.getTask(widget.existingTask!.id);
          if (originalTask != null) {
            final dates = originalTask.excludedDates?.toList() ?? [];
            final targetDate = widget.existingTask!.startTime ?? DateTime.now();
            final alreadyExcluded = dates.any((d) => d.year == targetDate.year && d.month == targetDate.month && d.day == targetDate.day);
            if (!alreadyExcluded) {
              dates.add(DateTime(targetDate.year, targetDate.month, targetDate.day));
              originalTask.excludedDates = dates;
              await db.saveTimeTask(originalTask);
            }
          }
        } else if (result == 'all') {
          await db.deleteTimeTask(widget.existingTask!.id);
        }
      } else {
        if (mounted) Navigator.of(context).pop();
        await db.deleteTimeTask(widget.existingTask!.id);
      }
    } else {
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final hintColor = isDark ? Colors.white54 : Colors.black38;
    final inputBgColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: bottomInset + 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.isFromTemplate ? 'New from Template' : (widget.existingTask != null ? 'Edit Task' : 'Add a new Task'),
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
                ),
                Row(
                  children: [
                    // Save as template
                    IconButton(
                      icon: Icon(Icons.content_copy_rounded, color: context.gradientPrimary),
                      tooltip: 'Save as Template',
                      onPressed: _saveAsTemplate,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 28),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Title with NLP parse button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: inputBgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _titleController,
                      autofocus: true,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
                      decoration: InputDecoration(
                        hintText: 'E.g. Call dentist tomorrow 3pm...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: hintColor, fontWeight: FontWeight.normal),
                      ),
                    ),
                  ),
                  if ((ref.watch(isProProvider).valueOrNull ?? false) || ref.watch(aiUsageCountProvider) < 3)
                  GestureDetector(
                    onTap: _tryAiParse,
                    child: Tooltip(
                      message: 'AI auto-fill all fields from title',
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: context.gradientPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.auto_awesome, color: context.gradientPrimary, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _tryNlpParse,
                    child: Tooltip(
                      message: 'Auto-detect date & time from title',
                      child: Icon(Icons.schedule, color: context.gradientSecondary, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Notes
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: inputBgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade200),
              ),
              child: TextField(
                controller: _notesController,
                maxLines: 2,
                style: TextStyle(fontSize: 15, color: textColor),
                decoration: InputDecoration(
                  hintText: 'Additional notes (optional)',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: hintColor),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Priority
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text('Priority', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            SizedBox(
              height: 44,
              child: Row(
                children: TaskPriority.values.map((p) {
                  final isSelected = _priority == p;
                  final color = TimeTask.priorityColors[p]!;
                  final icon = TimeTask.priorityIcons[p]!;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _priority = p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? color.withValues(alpha: 0.15) : inputBgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? color.withValues(alpha: 0.5) : Colors.transparent, width: 1.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(icon, size: 14, color: isSelected ? color : Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              p.name[0].toUpperCase() + p.name.substring(1),
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? color : Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Category
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: TaskCategory.values.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = TaskCategory.values[index];
                  final isSelected = _category == category;
                  Color color = Colors.grey;
                  switch (category) {
                    case TaskCategory.work: color = const Color(0xFF5B78E6); break;
                    case TaskCategory.personal: color = const Color(0xFF4AC287); break;
                    case TaskCategory.health: color = const Color(0xFFD65B82); break;
                    case TaskCategory.finance: color = const Color(0xFFD4A831); break;
                    case TaskCategory.other: color = const Color(0xFF9062D4); break;
                  }
                  return GestureDetector(
                    onTap: () => setState(() => _category = category),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: isSelected ? color.withValues(alpha: 0.15) : inputBgColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: isSelected ? color.withValues(alpha: 0.5) : Colors.transparent, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          category.name[0].toUpperCase() + category.name.substring(1),
                          style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? color : Colors.grey.shade600, fontSize: 15),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Date row
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(color: inputBgColor, borderRadius: BorderRadius.circular(16)),
                alignment: Alignment.center,
                child: Text(
                  _selectedDate != null ? DateFormat('MMMM d, y').format(_selectedDate!) : 'Set Date',
                  style: TextStyle(fontWeight: FontWeight.w500, color: _selectedDate != null ? textColor : hintColor),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Start / End time row
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickTime,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(color: inputBgColor, borderRadius: BorderRadius.circular(16)),
                      alignment: Alignment.center,
                      child: Text(
                        _timeOfDay != null ? 'Start: ${_timeOfDay!.format(context)}' : 'Start Time',
                        style: TextStyle(fontWeight: FontWeight.w500, color: _timeOfDay != null ? textColor : hintColor),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _pickEndTime,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(color: inputBgColor, borderRadius: BorderRadius.circular(16)),
                      alignment: Alignment.center,
                      child: Text(
                        _endTimeOfDay != null ? 'End: ${_endTimeOfDay!.format(context)}' : 'End Time',
                        style: TextStyle(fontWeight: FontWeight.w500, color: _endTimeOfDay != null ? textColor : hintColor),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Type / Recurrence row
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(color: inputBgColor, borderRadius: BorderRadius.circular(16)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<TaskType>(
                        value: _type,
                        isExpanded: true,
                        dropdownColor: bgColor,
                        icon: Icon(Icons.keyboard_arrow_down, color: textColor),
                        items: TaskType.values.map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.name[0].toUpperCase() + t.name.substring(1), style: TextStyle(fontWeight: FontWeight.w500, color: textColor)),
                        )).toList(),
                        onChanged: (val) { if (val != null) setState(() => _type = val); },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(color: inputBgColor, borderRadius: BorderRadius.circular(16)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<RecurrenceType>(
                        value: _recurrence,
                        isExpanded: true,
                        dropdownColor: bgColor,
                        icon: Icon(Icons.repeat, color: textColor),
                        items: RecurrenceType.values.map((r) => DropdownMenuItem(
                          value: r,
                          child: Text('Repeat: ${r.name[0].toUpperCase() + r.name.substring(1)}', style: TextStyle(fontWeight: FontWeight.w500, color: textColor)),
                        )).toList(),
                        onChanged: (val) { if (val != null) setState(() => _recurrence = val); },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Subtasks section
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text('Subtasks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            if (_subtasks.isNotEmpty) ...[
              ..._subtasks.asMap().entries.map((entry) {
                final i = entry.key;
                final sub = entry.value;
                final isDone = sub['done'] == true;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: inputBgColor, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _subtasks[i] = {...sub, 'done': !isDone}),
                        child: Icon(isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            size: 20, color: isDone ? Colors.greenAccent.shade400 : Colors.grey.shade400),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          sub['title']?.toString() ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDone ? textColor.withValues(alpha: 0.4) : textColor,
                            decoration: isDone ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _subtasks.removeAt(i)),
                        child: Icon(Icons.close, size: 16, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: inputBgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.add, size: 18, color: context.gradientPrimary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _subtaskController,
                      style: TextStyle(fontSize: 14, color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Add a subtask...',
                        border: InputBorder.none,
                        isDense: true,
                        hintStyle: TextStyle(color: hintColor, fontSize: 14),
                      ),
                      onSubmitted: (_) => _addSubtask(),
                    ),
                  ),
                  GestureDetector(
                    onTap: _addSubtask,
                    child: Text('Add', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.gradientPrimary)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Save / Delete row
            Row(
              children: [
                if (widget.existingTask != null && !widget.isFromTemplate) ...[
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: _delete,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        side: const BorderSide(color: Colors.redAccent),
                        foregroundColor: Colors.redAccent,
                      ),
                      child: const Text('Delete', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: context.primaryGradient,
                      boxShadow: [BoxShadow(color: context.gradientPrimary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8))],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _save,
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text('Save Task', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
