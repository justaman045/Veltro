import 'package:flutter_test/flutter_test.dart';
import 'package:agentic_todo/models/time_task.dart';

void main() {
  group('TimeTask.fromJson', () {
    test('parses full valid JSON correctly', () {
      final task = TimeTask.fromJson({
        'id': 'abc123',
        'title': 'Test Task',
        'notes': 'Some notes',
        'startTime': '2026-05-26T09:00:00.000',
        'endTime': '2026-05-26T10:00:00.000',
        'completedDates': ['2026-05-25T00:00:00.000'],
        'excludedDates': ['2026-05-24T00:00:00.000'],
        'type': 'task',
        'category': 'work',
        'isCompleted': false,
        'recurrence': 'daily',
        'priority': 'high',
        'subtasks': [
          {'title': 'sub1', 'done': false},
          {'title': 'sub2', 'done': true},
        ],
      });

      expect(task.id, 'abc123');
      expect(task.title, 'Test Task');
      expect(task.notes, 'Some notes');
      expect(task.startTime, DateTime(2026, 5, 26, 9, 0, 0));
      expect(task.endTime, DateTime(2026, 5, 26, 10, 0, 0));
      expect(task.completedDates, [DateTime(2026, 5, 25)]);
      expect(task.excludedDates, [DateTime(2026, 5, 24)]);
      expect(task.type, TaskType.task);
      expect(task.category, TaskCategory.work);
      expect(task.isCompleted, false);
      expect(task.recurrence, RecurrenceType.daily);
      expect(task.priority, TaskPriority.high);
      expect(task.subtasks!.length, 2);
      expect(task.completedSubtaskCount, 1);
      expect(task.totalSubtaskCount, 2);
      expect(task.hasSubtasks, true);
    });

    test('applies defaults for missing fields', () {
      final task = TimeTask.fromJson({'id': 'x'});
      expect(task.title, '');
      expect(task.notes, '');
      expect(task.startTime, null);
      expect(task.endTime, null);
      expect(task.completedDates, null);
      expect(task.excludedDates, null);
      expect(task.type, TaskType.task);
      expect(task.category, TaskCategory.personal);
      expect(task.isCompleted, false);
      expect(task.recurrence, RecurrenceType.none);
      expect(task.priority, TaskPriority.medium);
      expect(task.subtasks, null);
      expect(task.hasSubtasks, false);
    });

    test('parses category as work', () {
      final t = TimeTask.fromJson({'category': 'work'});
      expect(t.category, TaskCategory.work);
    });

    test('parses category as personal (default)', () {
      final t = TimeTask.fromJson({'category': null});
      expect(t.category, TaskCategory.personal);
    });

    test('handles invalid category gracefully', () {
      final t = TimeTask.fromJson({'category': 'invalid_cat'});
      expect(t.category, TaskCategory.personal);
    });

    test('handles invalid priority gracefully', () {
      final t = TimeTask.fromJson({'priority': 'super_urgent'});
      expect(t.priority, TaskPriority.medium);
    });

    test('handles invalid recurrence gracefully', () {
      final t = TimeTask.fromJson({'recurrence': 'yearly'});
      expect(t.recurrence, RecurrenceType.none);
    });

    test('handles invalid type gracefully', () {
      final t = TimeTask.fromJson({'type': 'widget'});
      expect(t.type, TaskType.task);
    });

    test('_parseDateTime handles String', () {
      final t = TimeTask.fromJson({'startTime': 'invalid-date'});
      expect(t.startTime, null);
    });

    test('_parseDateTime handles null', () {
      final t = TimeTask.fromJson({'startTime': null});
      expect(t.startTime, null);
    });

    test('_parseDateList handles non-list', () {
      final t = TimeTask.fromJson({'completedDates': 'not-a-list'});
      expect(t.completedDates, null);
    });

    test('_parseSubtasks handles non-list', () {
      final t = TimeTask.fromJson({'subtasks': 'not-a-list'});
      expect(t.subtasks, null);
    });

    test('toJson round-trip preserves all fields', () {
      final original = TimeTask()
        ..id = 'roundtrip-1'
        ..title = 'Round Trip'
        ..notes = 'Testing round trip'
        ..startTime = DateTime(2026, 5, 26, 14, 30)
        ..endTime = DateTime(2026, 5, 26, 15, 0)
        ..completedDates = [DateTime(2026, 5, 25)]
        ..excludedDates = [DateTime(2026, 5, 24)]
        ..type = TaskType.meeting
        ..category = TaskCategory.finance
        ..isCompleted = true
        ..recurrence = RecurrenceType.weekly
        ..priority = TaskPriority.high
        ..subtasks = [
          {'title': 'step 1', 'done': true},
          {'title': 'step 2', 'done': false},
        ];

      final json = original.toJson();
      final restored = TimeTask.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.notes, original.notes);
      expect(restored.startTime, original.startTime);
      expect(restored.endTime, original.endTime);
      expect(restored.completedDates, original.completedDates);
      expect(restored.excludedDates, original.excludedDates);
      expect(restored.type, original.type);
      expect(restored.category, original.category);
      expect(restored.isCompleted, original.isCompleted);
      expect(restored.recurrence, original.recurrence);
      expect(restored.priority, original.priority);
      expect(restored.subtasks!.length, 2);
      expect(restored.completedSubtaskCount, 1);
    });

    test('toJson excludes null dates', () {
      final task = TimeTask()..id = 'no-dates';
      final json = task.toJson();
      expect(json['startTime'], null);
      expect(json['endTime'], null);
      expect(json['completedDates'], null);
      expect(json['excludedDates'], null);
    });
  });
}
