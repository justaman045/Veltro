import 'package:flutter/material.dart';

enum TaskType { meeting, task, note }

enum TaskCategory { work, personal, health, finance, other }

enum RecurrenceType { none, daily, weekly, monthly, weekdays }

enum TaskPriority { low, medium, high }

class TimeTask {
  String id = '';
  String title = '';
  String notes = '';
  DateTime? startTime;
  DateTime? endTime;
  List<DateTime>? completedDates;
  List<DateTime>? excludedDates;
  TaskType type = TaskType.task;
  TaskCategory category = TaskCategory.personal;
  bool isCompleted = false;
  RecurrenceType recurrence = RecurrenceType.none;
  TaskPriority priority = TaskPriority.medium;
  List<Map<String, dynamic>>? subtasks;

  static const Map<TaskCategory, Color> categoryColors = {
    TaskCategory.work: Color(0xFF6366F1),
    TaskCategory.personal: Color(0xFFEC4899),
    TaskCategory.health: Color(0xFF14B8A6),
    TaskCategory.finance: Color(0xFFF59E0B),
    TaskCategory.other: Color(0xFF8B5CF6),
  };

  static const Map<TaskPriority, Color> priorityColors = {
    TaskPriority.low: Color(0xFF22C55E),
    TaskPriority.medium: Color(0xFFF59E0B),
    TaskPriority.high: Color(0xFFEF4444),
  };

  static const Map<TaskPriority, IconData> priorityIcons = {
    TaskPriority.low: Icons.arrow_downward_rounded,
    TaskPriority.medium: Icons.remove_rounded,
    TaskPriority.high: Icons.arrow_upward_rounded,
  };

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'notes': notes,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'completedDates': completedDates?.map((d) => d.toIso8601String()).toList(),
      'excludedDates': excludedDates?.map((d) => d.toIso8601String()).toList(),
      'type': type.name,
      'category': category.name,
      'isCompleted': isCompleted,
      'recurrence': recurrence.name,
      'priority': priority.name,
      'subtasks': subtasks,
    };
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      try { return DateTime.parse(value); } catch (_) {}
      return null;
    }
    try {
      final date = (value as dynamic).toDate();
      if (date is DateTime) return date;
    } catch (_) {}
    return null;
  }

  static List<DateTime>? _parseDateList(dynamic value) {
    if (value == null) return null;
    if (value is! List) return null;
    final result = <DateTime>[];
    for (final item in value) {
      final date = _parseDateTime(item);
      if (date != null) result.add(date);
    }
    return result.isEmpty ? null : result;
  }

  static List<Map<String, dynamic>>? _parseSubtasks(dynamic value) {
    if (value == null) return null;
    if (value is! List) return null;
    return value.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
  }

  static TimeTask fromJson(Map<String, dynamic> json) {
    return TimeTask()
      ..id = json['id'] as String? ?? ''
      ..title = json['title'] as String? ?? ''
      ..notes = json['notes'] as String? ?? ''
      ..startTime = _parseDateTime(json['startTime'])
      ..endTime = _parseDateTime(json['endTime'])
      ..completedDates = _parseDateList(json['completedDates'])
      ..excludedDates = _parseDateList(json['excludedDates'])
      ..type = TaskType.values.firstWhere((e) => e.name == json['type']?.toString().toLowerCase(), orElse: () => TaskType.task)
      ..category = TaskCategory.values.firstWhere((e) => e.name == json['category']?.toString().toLowerCase(), orElse: () => TaskCategory.personal)
      ..isCompleted = json['isCompleted'] as bool? ?? false
      ..recurrence = RecurrenceType.values.firstWhere((e) => e.name == json['recurrence']?.toString().toLowerCase(), orElse: () => RecurrenceType.none)
      ..priority = TaskPriority.values.firstWhere((e) => e.name == json['priority']?.toString().toLowerCase(), orElse: () => TaskPriority.medium)
      ..subtasks = _parseSubtasks(json['subtasks']);
  }

  int get completedSubtaskCount => subtasks?.where((s) => s['done'] == true).length ?? 0;
  int get totalSubtaskCount => subtasks?.length ?? 0;
  bool get hasSubtasks => subtasks != null && subtasks!.isNotEmpty;
}
