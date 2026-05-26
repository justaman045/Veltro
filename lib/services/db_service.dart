import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../models/time_task.dart';
import 'notification_service.dart';

class DbService {
  void _log(String msg) {
    try { FirebaseCrashlytics.instance.log('DbService: $msg'); } catch (_) {}
  }

  Future<void> init() async {
    // No local database to initialize
  }


  CollectionReference<Map<String, dynamic>>? get _tasksRef {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(user.email).collection('tasks');
  }

  Future<void> saveTimeTask(TimeTask task, {bool? userToggledCompletionState}) async {
    final ref = _tasksRef;
    // B2 fix: ref is null when user is not logged in — fail loudly instead of silently
    if (ref == null) {
      Get.snackbar(
        'Not Signed In',
        'Your task could not be saved. Please sign in again.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.cloud_off, color: Colors.white),
      );
      return;
    }

    final isNew = task.id.isEmpty;
    if (isNew) {
      task.id = ref.doc().id;
    }

    try {
      await ref.doc(task.id).set(task.toJson(), SetOptions(merge: true));
      _log('saveTimeTask success: ${task.id} (isNew=$isNew)');
    } catch (e) {
      _log('saveTimeTask failed: $e');
      debugPrint('Firebase Sync Error: $e');
      Get.snackbar(
        'Sync Failed',
        'Could not save your task. Check your connection.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.cloud_off, color: Colors.white),
      );
      return;
    }
    
    // Schedule or update notification
    try {
      if (!task.isCompleted) {
        await NotificationService().scheduleTaskReminder(task);
      } else {
        await NotificationService().cancelTaskNotification(task.id);
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

  Future<void> deleteTimeTask(String id, {bool suppressSnackbar = false}) async {
    final ref = _tasksRef;
    if (ref != null) {
      try {
        await ref.doc(id).delete();
        _log('deleteTimeTask success: $id');
      } catch (e) {
        _log('deleteTimeTask failed: $e');
        debugPrint('Firebase Sync Error: $e');
        Get.snackbar(
          'Delete Failed',
          'Could not delete the task. Check your connection.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 3),
          icon: const Icon(Icons.cloud_off, color: Colors.white),
        );
        return;
      }
    }
    
    await NotificationService().cancelTaskNotification(id);

    if (!suppressSnackbar) {
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
  }

  TimeTask? _safeParseTask(Map<String, dynamic> data, String docId) {
    try {
      return TimeTask.fromJson(data);
    } catch (e) {
      debugPrint('Corrupt task doc $docId: $e');
      debugPrint('Raw data: $data');
      return null;
    }
  }

  Stream<List<TimeTask>> watchTodos() {
    final ref = _tasksRef;
    if (ref == null) return Stream.value([]);

    return ref.snapshots().map((snapshot) {
      return snapshot.docs
        .map((doc) => _safeParseTask(doc.data(), doc.id))
        .whereType<TimeTask>()
        .toList()
        ..sort((a, b) {
          // High priority first
          final pComp = b.priority.index.compareTo(a.priority.index);
          if (pComp != 0) return pComp;
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
      final allDbTasks = snapshot.docs
        .map((doc) => _safeParseTask(doc.data(), doc.id))
        .whereType<TimeTask>()
        .toList();
      
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
          ..category = t.category
          ..priority = t.priority
          ..subtasks = t.subtasks?.map((s) => Map<String, dynamic>.from(s)).toList();
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

  Future<TimeTask?> getTask(String id) async {
    final ref = _tasksRef;
    if (ref == null) return null;
    final doc = await ref.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return _safeParseTask(doc.data()!, doc.id);
  }

  Future<List<TimeTask>> getAllTasks() async {
    final ref = _tasksRef;
    if (ref == null) return [];
    
    final snapshot = await ref.get();
    return snapshot.docs
      .map((doc) => _safeParseTask(doc.data(), doc.id))
      .whereType<TimeTask>()
      .toList();
  }

  // ─── Templates ───────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>>? get _templatesRef {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(user.email).collection('templates');
  }

  Future<void> saveTemplate(TimeTask template) async {
    final ref = _templatesRef;
    if (ref == null) return;
    if (template.id.isEmpty) template.id = ref.doc().id;
    await ref.doc(template.id).set(template.toJson());
    _log('saveTemplate: ${template.id}');
  }

  Future<void> deleteTemplate(String id) async {
    await _templatesRef?.doc(id).delete();
    _log('deleteTemplate: $id');
  }

  Stream<List<TimeTask>> watchTemplates() {
    final ref = _templatesRef;
    if (ref == null) return Stream.value([]);
    return ref.snapshots().map((s) =>
      s.docs.map((doc) => _safeParseTask(doc.data(), doc.id)).whereType<TimeTask>().toList()
    );
  }

  // ─── Profile ─────────────────────────────────────────────────────────────

  Future<void> saveProfileData(Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.email).set(data, SetOptions(merge: true));
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
        _log('clearAllData success');
      } catch (e) {
        _log('clearAllData failed: $e');
        debugPrint('Firebase Wipe Error: $e');
      }
    }
  }
}
