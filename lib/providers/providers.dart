import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/time_task.dart';
import '../services/db_service.dart';
import '../services/auth_service.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
AuthService authService(AuthServiceRef ref) {
  return AuthService();
}

@riverpod
Stream<User?> authState(AuthStateRef ref) {
  return ref.watch(authServiceProvider).authStateChanges;
}

@Riverpod(keepAlive: true)
DbService dbService(DbServiceRef ref) {
  throw UnimplementedError('dbService provider was not initialized');
}

@riverpod
Stream<List<TimeTask>> timelineTasks(TimelineTasksRef ref, DateTime date) {
  final db = ref.watch(dbServiceProvider);
  return db.watchTimeline(date);
}

@riverpod
Stream<List<TimeTask>> todoTasks(TodoTasksRef ref) {
  final db = ref.watch(dbServiceProvider);
  return db.watchTodos();
}

@riverpod
Future<Map<String, dynamic>?> userProfileData(UserProfileDataRef ref) async {
  final user = ref.watch(authServiceProvider).currentUser;
  if (user == null || user.email == null) return null;
  
  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.email)
        .get();
        
    if (doc.exists) {
      return doc.data();
    }
  } catch (e) {
    debugPrint('Error fetching user profile data: $e');
  }
  return null;
}

