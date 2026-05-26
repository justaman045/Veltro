import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../models/time_task.dart';
import '../services/db_service.dart';
import '../services/auth_service.dart';
import '../services/subscription_service.dart';
import '../services/ai_service.dart';

part 'providers.g.dart';

final calendarJumpDateProvider = StateProvider<DateTime?>((ref) => null);

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

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  throw UnimplementedError('subscriptionService provider was not initialized');
});

final isProProvider = StreamProvider<bool>((ref) {
  return ref.watch(subscriptionServiceProvider).isProStream;
});

final offeringsProvider = FutureProvider<Offerings?>((ref) {
  return ref.watch(subscriptionServiceProvider).getOfferings();
});

@Riverpod(keepAlive: true)
AiService aiService(AiServiceRef ref) {
  throw UnimplementedError('aiService provider was not initialized');
}

final aiUsageCountProvider = StateProvider<int>((ref) => 0);

final openRouterModelsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final ai = ref.watch(aiServiceProvider);
  return ai.fetchModels();
});

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
Future<List<TimeTask>> allTasks(AllTasksRef ref) {
  return ref.watch(dbServiceProvider).getAllTasks();
}

@riverpod
Stream<List<TimeTask>> templateTasks(TemplateTasksRef ref) {
  return ref.watch(dbServiceProvider).watchTemplates();
}

@riverpod
Future<String> dailyBriefing(DailyBriefingRef ref) async {
  final aiService = ref.watch(aiServiceProvider);
  final allTasks = await ref.watch(allTasksProvider.future);
  final userName = ref.watch(authServiceProvider).currentUser?.displayName ?? 'there';

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final todayTasks = allTasks.where((t) {
    if (t.startTime == null || t.isCompleted) return false;
    final d = t.startTime!;
    return d.year == today.year && d.month == today.month && d.day == today.day;
  }).toList();

  return aiService.dailyBriefing(todayTasks, userName);
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
