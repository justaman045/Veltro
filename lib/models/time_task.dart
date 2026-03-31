enum TaskType {
  meeting,
  task,
  note
}

enum TaskCategory {
  work,
  personal,
  health,
  finance,
  other
}

enum RecurrenceType {
  none,
  daily,
  weekly,
  monthly,
  weekdays
}

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

  // Serialization for Firebase Sync
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
    };
  }

  static TimeTask fromJson(Map<String, dynamic> json) {
    return TimeTask()
      ..id = json['id'] as String? ?? ''
      ..title = json['title'] as String? ?? ''
      ..notes = json['notes'] as String? ?? ''
      ..startTime = json['startTime'] != null ? DateTime.parse(json['startTime'] as String) : null
      ..endTime = json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null
      ..completedDates = (json['completedDates'] as List<dynamic>?)?.map((d) => DateTime.parse(d as String)).toList()
      ..excludedDates = (json['excludedDates'] as List<dynamic>?)?.map((d) => DateTime.parse(d as String)).toList()
      ..type = TaskType.values.firstWhere((e) => e.name == json['type']?.toString().toLowerCase(), orElse: () => TaskType.task)
      ..category = TaskCategory.values.firstWhere((e) => e.name == json['category']?.toString().toLowerCase(), orElse: () => TaskCategory.personal)
      ..isCompleted = json['isCompleted'] as bool? ?? false
      ..recurrence = RecurrenceType.values.firstWhere((e) => e.name == json['recurrence']?.toString().toLowerCase(), orElse: () => RecurrenceType.none);
  }
}
