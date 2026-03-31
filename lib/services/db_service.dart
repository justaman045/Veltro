import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Rx;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/time_task.dart';
import 'notification_service.dart';

class DbService {
  Future<void> init() async {
    // No local database to initialize
  }

  void startCloudSync(User user) {}
  void stopCloudSync() {}

  CollectionReference<Map<String, dynamic>>? get _tasksRef {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(user.email).collection('tasks');
  }

  Future<void> saveTimeTask(TimeTask task, {bool? userToggledCompletionState}) async {
    final ref = _tasksRef;
    final isNew = task.id.isEmpty;
    if (isNew) {
      task.id = ref?.doc().id ?? DateTime.now().millisecondsSinceEpoch.toString();
    }
    
    if (ref != null) {
      try {
        await ref.doc(task.id).set(task.toJson(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firebase Sync Error: $e');
      }
    }
    
    // Schedule or update notification
    try {
      if (!task.isCompleted) {
        await NotificationService().scheduleTaskReminder(task);
      } else {
        await NotificationService().cancelNotification(task.id.hashCode);
      }
    } catch (e) {
      debugPrint('Warning: Could not schedule notification: $e');
    }
    
    String snackTitle = isNew ? 'Task Created' : 'Task Updated';
    String snackMessage = isNew ? 'Your new task has been scheduled.' : 'Your changes have been saved.';
    IconData snackIcon = Icons.check_circle_outline;

    if (userToggledCompletionState != null) {
      snackTitle = userToggledCompletionState ? 'Task Completed' : 'Task Reopened';
      snackMessage = userToggledCompletionState ? 'Great job finishing this task!' : 'Task moved back to pending.';
      snackIcon = userToggledCompletionState ? Icons.task_alt : Icons.history;
    }
    
    Get.snackbar(
      snackTitle,
      snackMessage,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
      icon: Icon(snackIcon, color: Colors.greenAccent),
    );
  }

  Future<void> deleteTimeTask(String id) async {
    final ref = _tasksRef;
    if (ref != null) {
      try {
        await ref.doc(id).delete();
      } catch (e) {
        debugPrint('Firebase Sync Error: $e');
      }
    }
    
    // Cancel notification
    await NotificationService().cancelNotification(id.hashCode);
    
    Get.snackbar(
      'Task Deleted',
      'The task was successfully removed.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
    );
  }

  Stream<List<TimeTask>> watchTodos() {
    final ref = _tasksRef;
    if (ref == null) return Stream.value([]);
    
    return ref.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => TimeTask.fromJson(doc.data())).toList()
        ..sort((a, b) {
          if (a.startTime == null && b.startTime == null) return 0;
          if (a.startTime == null) return -1;
          if (b.startTime == null) return 1;
          return a.startTime!.compareTo(b.startTime!);
        });
    });
  }
  
  Stream<List<TimeTask>> watchTimeline(DateTime date) {
    final ref = _tasksRef;
    if (ref == null) return Stream.value([]);
    
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
    
    return ref.snapshots().map((snapshot) {
      final allDbTasks = snapshot.docs.map((doc) => TimeTask.fromJson(doc.data())).toList();
      
      final normalTasks = allDbTasks.where((t) {
        if (t.recurrence != RecurrenceType.none) return false;
        if (t.startTime == null) return false;
        return t.startTime!.isAfter(startOfDay.subtract(const Duration(milliseconds: 1))) && 
               t.startTime!.isBefore(endOfDay.add(const Duration(milliseconds: 1)));
      }).toList();
      
      final recurringTasks = allDbTasks.where((t) {
        if (t.recurrence == RecurrenceType.none) return false;
        if (t.startTime == null) return false;
        return t.startTime!.isBefore(endOfDay.add(const Duration(milliseconds: 1)));
      }).toList();
      
      final now = DateTime.now();
      final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
      
      List<TimeTask> pastPendingTasks = [];
      if (isToday) {
        pastPendingTasks = allDbTasks.where((t) {
          if (t.isCompleted) return false;
          if (t.recurrence != RecurrenceType.none) return false;
          if (t.startTime == null) return false;
          return t.startTime!.isBefore(startOfDay);
        }).toList();
      }
      
      final projectedRecurringTasks = recurringTasks.where((t) {
        if (t.startTime == null) return false;
        
        final isExcludedOnDay = t.excludedDates?.any((d) => 
          d.year == date.year && d.month == date.month && d.day == date.day
        ) ?? false;
        if (isExcludedOnDay) return false;

        switch (t.recurrence) {
          case RecurrenceType.daily: return true;
          case RecurrenceType.weekly: return t.startTime!.weekday == date.weekday;
          case RecurrenceType.monthly: return t.startTime!.day == date.day;
          case RecurrenceType.weekdays: return date.weekday >= 1 && date.weekday <= 5;
          case RecurrenceType.none: return false;
        }
      }).map((t) {
        final originalTime = t.startTime;
        DateTime? newStartTime;
        if (originalTime != null) {
          newStartTime = DateTime(date.year, date.month, date.day, originalTime.hour, originalTime.minute);
        }
        
        final isCompletedOnDay = t.completedDates?.any((d) => 
          d.year == date.year && d.month == date.month && d.day == date.day
        ) ?? false;
        
        return TimeTask()
          ..id = t.id
          ..title = t.title
          ..notes = t.notes
          ..startTime = newStartTime
          ..endTime = t.endTime
          ..isCompleted = isCompletedOnDay
          ..recurrence = t.recurrence
          ..completedDates = t.completedDates?.toList()
          ..excludedDates = t.excludedDates?.toList()
          ..type = t.type
          ..category = t.category;
      }).toList();
      
      var allTasks = [...normalTasks, ...projectedRecurringTasks, ...pastPendingTasks];
      
      final seenIds = <String>{};
      allTasks = allTasks.where((task) => seenIds.add(task.id)).toList();
      
      allTasks.sort((a, b) {
        if (a.startTime == null && b.startTime == null) return 0;
        if (a.startTime == null) return -1;
        if (b.startTime == null) return 1;
        return a.startTime!.compareTo(b.startTime!);
      });
      
      return allTasks;
    });
  }

  Stream<List<TimeTask>> watchPastPendingTasks(DateTime date) {
    final ref = _tasksRef;
    if (ref == null) return Stream.value([]);
    
    final startOfDay = DateTime(date.year, date.month, date.day);
    
    return ref.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => TimeTask.fromJson(doc.data())).where((t) {
        if (t.isCompleted) return false;
        if (t.recurrence != RecurrenceType.none) return false;
        if (t.startTime == null) return false;
        return t.startTime!.isBefore(startOfDay);
      }).toList();
    });
  }
  
  Future<TimeTask?> getTask(String id) async {
    final ref = _tasksRef;
    if (ref == null) return null;
    final doc = await ref.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return TimeTask.fromJson(doc.data()!);
  }

  Future<List<TimeTask>> getAllTasks() async {
    final ref = _tasksRef;
    if (ref == null) return [];
    
    final snapshot = await ref.get();
    return snapshot.docs.map((doc) => TimeTask.fromJson(doc.data())).toList();
  }

  Future<void> clearAllData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      try {
        final tasksRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.email)
            .collection('tasks');
            
        final snapshot = await tasksRef.get();
        if (snapshot.docs.isNotEmpty) {
          final batch = FirebaseFirestore.instance.batch();
          for (final doc in snapshot.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
        }
        
        // Also wipe the root profile document holding their settings/meta
        await FirebaseFirestore.instance.collection('users').doc(user.email).delete();
      } catch (e) {
        debugPrint('Firebase Wipe Error: $e');
      }
    }
  }
}
