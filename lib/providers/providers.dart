import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

final isAdminProvider = StreamProvider<bool>((ref) {
  return ref.watch(subscriptionServiceProvider).isAdminStream;
});

final tierProvider = StreamProvider<String>((ref) {
  return ref.watch(subscriptionServiceProvider).tierStream;
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
Future<Map<String, dynamic>?> userProfileData(UserProfileDataRef ref) async {
  final user = ref.watch(authServiceProvider).currentUser;
  if (user == null || user.email == null) return null;

  try {
    final db = ref.watch(dbServiceProvider);
    return db.getUserDocData(user.email!);
  } catch (e) {
    debugPrint('Error fetching user profile data: $e');
  }
  return null;
}
