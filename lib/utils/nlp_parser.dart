import 'package:flutter/material.dart';

class NlpParser {
  static const Map<String, int> _weekdays = {
    'monday': 1, 'tuesday': 2, 'wednesday': 3, 'thursday': 4,
    'friday': 5, 'saturday': 6, 'sunday': 7,
    'mon': 1, 'tue': 2, 'wed': 3, 'thu': 4, 'fri': 5, 'sat': 6, 'sun': 7,
  };

  static ({DateTime? date, TimeOfDay? time}) parse(String text) {
    final lower = text.toLowerCase();
    DateTime? date;
    TimeOfDay? time;

    final timeRegex = RegExp(r'(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)', caseSensitive: false);
    final timeMatch = timeRegex.firstMatch(lower);
    if (timeMatch != null) {
      var hour = int.parse(timeMatch.group(1)!);
      final minute = int.parse(timeMatch.group(2) ?? '0');
      final period = timeMatch.group(3)!.toLowerCase();
      if (period == 'pm' && hour != 12) hour += 12;
      if (period == 'am' && hour == 12) hour = 0;
      if (hour < 24 && minute < 60) time = TimeOfDay(hour: hour, minute: minute);
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (lower.contains('today')) {
      date = today;
    } else if (lower.contains('tomorrow')) {
      date = today.add(const Duration(days: 1));
    } else {
      for (final entry in _weekdays.entries) {
        if (RegExp(r'\b' + entry.key + r'\b').hasMatch(lower)) {
          var daysUntil = entry.value - now.weekday;
          if (daysUntil <= 0) daysUntil += 7;
          date = today.add(Duration(days: daysUntil));
          break;
        }
      }
    }

    return (date: date, time: time);
  }
}
