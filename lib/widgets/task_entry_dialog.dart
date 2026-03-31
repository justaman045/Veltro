import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/time_task.dart';
import '../providers/providers.dart';

class TaskEntryDialog extends ConsumerStatefulWidget {
  final TimeTask? existingTask;

  const TaskEntryDialog({super.key, this.existingTask});

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

  @override
  void initState() {
    super.initState();
    if (widget.existingTask != null) {
      final t = widget.existingTask!;
      _titleController.text = t.title;
      _notesController.text = t.notes;
      _type = t.type;
      _category = t.category;
      _recurrence = t.recurrence;
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
    super.dispose();
  }
  
  void _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  void _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _timeOfDay ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        _timeOfDay = time;
      });
    }
  }

  void _pickEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _endTimeOfDay ?? _timeOfDay ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        _endTimeOfDay = time;
      });
    }
  }

  Future<String?> _showRecurringOverrideDialog(String actionDescription) {
    return Get.dialog<String>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Recurring Task'),
        content: Text('Do you want to apply this $actionDescription to this event only, or to all events in the series?'),
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
  }

  DateTime? _getFinalStartTime() {
    if (_timeOfDay != null && _selectedDate != null) {
      return DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _timeOfDay!.hour, _timeOfDay!.minute);
    }
    return null; // Return null if user hasn't explicitly set a time
  }

  DateTime? _getFinalEndTime() {
    if (_endTimeOfDay != null && _selectedDate != null) {
      return DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _endTimeOfDay!.hour, _endTimeOfDay!.minute);
    }
    return null; // Return null if user hasn't explicitly set a time
  }

  void _save() async {
    if (_titleController.text.isEmpty) return;
    
    final db = ref.read(dbServiceProvider);
    
    if (widget.existingTask != null && widget.existingTask!.recurrence != RecurrenceType.none) {
      final result = await _showRecurringOverrideDialog('edit');
      if (result == null) return;
      
      if (result == 'single') {
        final originalTask = await db.getTask(widget.existingTask!.id);
        if (originalTask != null) {
          final dates = originalTask.excludedDates?.toList() ?? [];
          final targetDate = widget.existingTask!.startTime ?? DateTime.now();
          
          final alreadyExcluded = dates.any((d) => 
            d.year == targetDate.year && d.month == targetDate.month && d.day == targetDate.day
          );
          
          if (!alreadyExcluded) {
            dates.add(DateTime(targetDate.year, targetDate.month, targetDate.day));
            originalTask.excludedDates = dates;
            // Save quietly so we don't spam snackbars
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
          ..isCompleted = widget.existingTask?.isCompleted ?? false;
          
        
        if (mounted) {
          Navigator.of(context).pop();
        }
        await db.saveTimeTask(newTask);
        return;
      }
    }
    
    final task = widget.existingTask ?? TimeTask();
    
    task
      ..title = _titleController.text
      ..notes = _notesController.text
      ..type = _type
      ..category = _category
      ..startTime = _getFinalStartTime()
      ..endTime = _getFinalEndTime()
      ..recurrence = _recurrence
      ..isCompleted = widget.existingTask?.isCompleted ?? false;
      
    if (mounted) {
      Navigator.of(context).pop();
    }
      
    await db.saveTimeTask(task);
  }

  void _delete() async {
    final db = ref.read(dbServiceProvider);
    
    if (widget.existingTask != null) {
      if (widget.existingTask!.recurrence != RecurrenceType.none) {
        final result = await _showRecurringOverrideDialog('deletion');
        if (result == null) return;
        
        if (mounted) {
          Navigator.of(context).pop(); // Close task entry dialog before DB calls
        }
        
        if (result == 'single') {
          final originalTask = await db.getTask(widget.existingTask!.id);
          if (originalTask != null) {
            final dates = originalTask.excludedDates?.toList() ?? [];
            final targetDate = widget.existingTask!.startTime ?? DateTime.now();
            
            final alreadyExcluded = dates.any((d) => 
              d.year == targetDate.year && d.month == targetDate.month && d.day == targetDate.day
            );
            
            if (!alreadyExcluded) {
              dates.add(DateTime(targetDate.year, targetDate.month, targetDate.day));
              originalTask.excludedDates = dates;
              // Save it quietly
              await db.saveTimeTask(originalTask);
            }
          }
        } else if (result == 'all') {
          await db.deleteTimeTask(widget.existingTask!.id);
        }
      } else {
        if (mounted) {
          Navigator.of(context).pop(); // Close task entry dialog before DB calls
        }
        // Normal single task deletion
        await db.deleteTimeTask(widget.existingTask!.id);
      }
    } else {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine bottom padding for keyboard
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final hintColor = isDark ? Colors.white54 : Colors.black38;
    final inputBgColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100;
    
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: bottomInset + 32, // Padding above keyboard
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.existingTask != null ? 'Edit Task' : 'Add a new Task',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 28),
                onPressed: () => Get.back(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Custom Text Field for Title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: inputBgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade200),
            ),
            child: TextField(
              controller: _titleController,
              autofocus: true,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
              decoration: InputDecoration(
                hintText: 'E.g. Read a book, Client meeting...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: hintColor, fontWeight: FontWeight.normal),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Text Field for Notes
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
          const SizedBox(height: 24),

          // Category Selector via Horizontal Chips
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: TaskCategory.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = TaskCategory.values[index];
                final isSelected = _category == category;
                
                // Map colors roughly based on the gradient scheme
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withValues(alpha: 0.15) : inputBgColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected ? color.withValues(alpha: 0.5) : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        category.name[0].toUpperCase() + category.name.substring(1),
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? color : Colors.grey.shade600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Action row for Date
          Row(
            children: [
              // Date Selector Button
              Expanded(
                child: InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: inputBgColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _selectedDate != null ? DateFormat('MMMM d, y').format(_selectedDate!) : 'Set Date',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: _selectedDate != null ? textColor : hintColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Action row for Times
          Row(
            children: [
              // Start Time Selector Button
              Expanded(
                child: InkWell(
                  onTap: _pickTime,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: inputBgColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _timeOfDay != null ? 'Start: ${_timeOfDay!.format(context)}' : 'Start Time',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: _timeOfDay != null ? textColor : hintColor,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // End Time Selector Button
              Expanded(
                child: InkWell(
                  onTap: _pickEndTime,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: inputBgColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _endTimeOfDay != null ? 'End: ${_endTimeOfDay!.format(context)}' : 'End Time',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: _endTimeOfDay != null ? textColor : hintColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Action row for Type and Recurring
          Row(
            children: [
              // Type Selector
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: inputBgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<TaskType>(
                      value: _type,
                      isExpanded: true,
                      dropdownColor: bgColor, // Popout background map
                      icon: Icon(Icons.keyboard_arrow_down, color: textColor),
                      items: TaskType.values.map((t) {
                        return DropdownMenuItem(
                          value: t,
                          child: Text(
                            t.name[0].toUpperCase() + t.name.substring(1),
                            style: TextStyle(fontWeight: FontWeight.w500, color: textColor),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _type = val);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Recurring Dropdown
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: inputBgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<RecurrenceType>(
                      value: _recurrence,
                      isExpanded: true,
                      dropdownColor: bgColor,
                      icon: Icon(Icons.repeat, color: textColor),
                      items: RecurrenceType.values.map((r) {
                        return DropdownMenuItem(
                          value: r,
                          child: Text(
                            'Repeat: ${r.name[0].toUpperCase() + r.name.substring(1)}',
                            style: TextStyle(fontWeight: FontWeight.w500, color: textColor),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _recurrence = val);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          Row(
            children: [
              if (widget.existingTask != null) ...[
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: _delete,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      side: const BorderSide(color: Colors.redAccent),
                      foregroundColor: Colors.redAccent,
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _save,
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'Save Task',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
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
    );
  }
}
