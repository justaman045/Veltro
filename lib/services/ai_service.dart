import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../models/time_task.dart';

// @visibleForTesting
TaskPriority aiParsePriority(String? p) {
  switch (p?.toLowerCase()) {
    case 'low': return TaskPriority.low;
    case 'high': return TaskPriority.high;
    case 'urgent': return TaskPriority.high;
    default: return TaskPriority.medium;
  }
}

// @visibleForTesting
TaskCategory aiParseCategory(String? c) {
  switch (c?.toLowerCase()) {
    case 'work': return TaskCategory.work;
    case 'health': return TaskCategory.health;
    case 'finance': return TaskCategory.finance;
    case 'growth': return TaskCategory.other;
    case 'personal': return TaskCategory.personal;
    default: return TaskCategory.other;
  }
}

class AiService {
  final String _apiKey;
  static const String _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';
  static const String _modelsUrl = 'https://openrouter.ai/api/v1/models';
  static const String _defaultModel = 'openai/gpt-oss-120b:free';
  static const int _maxRetries = 3;
  static const Duration _circuitBreakerDuration = Duration(seconds: 30);

  String _model;

  AiService(this._apiKey, {String model = _defaultModel}) : _model = model;

  String get model => _model;
  void setModel(String value) { _model = value; _logBreadcrumb('AiService: model changed to $value'); }

  final Duration _rateLimitInterval = const Duration(seconds: 2);
  DateTime _lastCall = DateTime(0);

  int _consecutiveFailures = 0;
  DateTime? _circuitOpenUntil;

  void _logBreadcrumb(String message) {
    try {
      FirebaseCrashlytics.instance.log(message);
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> fetchModels() async {
    _logBreadcrumb('AiService.fetchModels: requesting $_modelsUrl');
    final response = await http
        .get(Uri.parse(_modelsUrl), headers: {'Content-Type': 'application/json'})
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      _logBreadcrumb('AiService.fetchModels: failed with ${response.statusCode}');
      throw Exception('OpenRouter models API returned ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) throw Exception('OpenRouter API returned unexpected format');
    final data = decoded as Map<String, dynamic>;
    final list = data['data'] as List? ?? [];
    _logBreadcrumb('AiService.fetchModels: parsed ${list.length} models');
    return list.map((m) {
      final item = m as Map<String, dynamic>;
      final pricing = item['pricing'] as Map<String, dynamic>? ?? {};
      final promptPrice = double.tryParse(pricing['prompt']?.toString() ?? '') ?? 0;
      final completionPrice = double.tryParse(pricing['completion']?.toString() ?? '') ?? 0;
      final isFree = promptPrice == 0 && completionPrice == 0;
      return {
        'id': item['id']?.toString() ?? '',
        'name': item['name']?.toString() ?? item['id']?.toString() ?? '',
        'isFree': isFree,
      };
    }).toList();
  }

  Future<String> _rateLimitedCall(String prompt) async {
    if (_circuitOpenUntil != null && DateTime.now().isBefore(_circuitOpenUntil!)) {
      _logBreadcrumb('AiService: circuit breaker open, rejecting call');
      throw Exception('AI service temporarily unavailable (too many failures)');
    }

    final now = DateTime.now();
    final elapsed = now.difference(_lastCall);
    if (elapsed < _rateLimitInterval) {
      await Future.delayed(_rateLimitInterval - elapsed);
    }
    _lastCall = DateTime.now();

    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        final response = await http
            .post(
              Uri.parse(_baseUrl),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $_apiKey',
                'HTTP-Referer': 'https://agentic-todo.app',
                'X-Title': 'Agentic Todo',
              },
              body: jsonEncode({
                'model': _model,
                'messages': [
                  {'role': 'user', 'content': prompt},
                ],
                'temperature': 0.1,
                'max_tokens': 1024,
              }),
            )
            .timeout(const Duration(seconds: 30));

        if (response.statusCode == 429) {
          _consecutiveFailures++;
          _logBreadcrumb('AiService: 429 rate-limited (attempt $attempt/$_maxRetries)');
          if (_consecutiveFailures >= 5) {
            _circuitOpenUntil = DateTime.now().add(_circuitBreakerDuration);
            _logBreadcrumb('AiService: circuit breaker opened');
          }
          if (attempt < _maxRetries) {
            await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
            continue;
          }
          _consecutiveFailures = 0;
          throw Exception('AI rate limited after $_maxRetries retries');
        }

        if (response.statusCode >= 500) {
          _consecutiveFailures++;
          _logBreadcrumb('AiService: ${response.statusCode} server error (attempt $attempt/$_maxRetries)');
          if (_consecutiveFailures >= 5) {
            _circuitOpenUntil = DateTime.now().add(_circuitBreakerDuration);
            _logBreadcrumb('AiService: circuit breaker opened');
          }
          if (attempt < _maxRetries) {
            await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
            continue;
          }
          _consecutiveFailures = 0;
          throw Exception('AI request failed: ${response.statusCode} ${response.body}');
        }

        if (response.statusCode != 200) {
          _consecutiveFailures = 0;
          throw Exception('AI request failed: ${response.statusCode} ${response.body}');
        }

        _consecutiveFailures = 0;

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List;
        if (choices.isEmpty) {
          throw Exception('AI returned no choices');
        }
        final choice = choices[0];
        if (choice is! Map) throw Exception('Unexpected AI response format');
        final message = choice['message'];
        if (message is! Map) throw Exception('Unexpected AI response format');
        final content = message['content'] as String? ?? '';
        return content.trim();
      } on TimeoutException {
        _consecutiveFailures++;
        _logBreadcrumb('AiService: timeout (attempt $attempt/$_maxRetries)');
        if (_consecutiveFailures >= 5) {
          _circuitOpenUntil = DateTime.now().add(_circuitBreakerDuration);
          _logBreadcrumb('AiService: circuit breaker opened');
        }
        if (attempt < _maxRetries) {
          await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
          continue;
        }
        _consecutiveFailures = 0;
        rethrow;
      }
    }

    throw Exception('Max retries exceeded');
  }

  Future<Map<String, dynamic>> parseTaskFromText(String text) async {
    final prompt = '''
Extract task details from this text. Return ONLY valid JSON with these fields:
- "title": string (required)
- "category": one of "work", "personal", "health", "finance", "growth", "other"
- "priority": one of "low", "medium", "high", "urgent"
- "recurrence": one of "none", "daily", "weekly", "monthly", "weekdays"
- "notes": string (can be empty)
- "hasDate": boolean
- "date": ISO date string or null
- "hasTime": boolean
- "time": "HH:mm" string or null
- "durationMinutes": number or null

Text: "$text"
''';

    try {
      final result = await _rateLimitedCall(prompt);
      final cleaned = result.replaceAll(RegExp(r'^```(?:json)?\s*|\s*```$', multiLine: true), '').trim();
      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      _logBreadcrumb('AiService.parseTaskFromText failed: $e');
      debugPrint('AI parseTaskFromText failed: $e');
      return {'title': text, 'category': 'other', 'priority': 'medium', 'recurrence': 'none', 'notes': ''};
    }
  }

  Future<List<TimeTask>> breakdownTask(String goal) async {
    final prompt = '''
Break this goal into a list of specific, actionable subtasks with suggested scheduling.
Return ONLY valid JSON array. Each item must have:
- "title": string (required)
- "notes": string (optional)
- "suggestedDay": "today", "tomorrow", or day name like "Monday"
- "suggestedTime": "HH:mm" string or null
- "priority": "low", "medium", "high", or "urgent"
- "category": "work", "personal", "health", "finance", "growth", or "other"
- "estimatedMinutes": number or null

Goal: "$goal"

Return 3-8 items. Make them specific and actionable.
''';

    try {
      final result = await _rateLimitedCall(prompt);
      final cleaned = result.replaceAll(RegExp(r'^```(?:json)?\s*|\s*```$', multiLine: true), '').trim();
      final list = jsonDecode(cleaned) as List;
      return list.map((item) {
        final m = item as Map<String, dynamic>;
        final task = TimeTask();
        task.title = m['title']?.toString() ?? goal;
        task.notes = m['notes']?.toString() ?? '';
        task.priority = _parsePriority(m['priority']?.toString());
        task.category = _parseCategory(m['category']?.toString());
        return task;
      }).toList();
    } catch (e) {
      _logBreadcrumb('AiService.breakdownTask failed: $e');
      debugPrint('AI breakdownTask failed: $e');
      return [];
    }
  }

  Future<String> dailyBriefing(List<TimeTask> todayTasks, String userName) async {
    if (todayTasks.isEmpty) return '';

    final tasksText = todayTasks.map((t) {
      final time = t.startTime != null ? ' at ${t.startTime!.hour}:${(t.startTime!.minute).toString().padLeft(2, '0')}' : '';
      final prio = t.priority.name;
      final completed = t.isCompleted ? ' [COMPLETED]' : '';
      return '- "${t.title}"$time ($prio)$completed';
    }).join('\n');

    final prompt = '''
You are an AI productivity assistant. Given today's tasks for a user named "$userName", provide a brief 2-3 sentence briefing.
Keep it concise and helpful. Mention the top priority if there is one.

Today's tasks:
$tasksText
''';

    try {
      return await _rateLimitedCall(prompt);
    } catch (e) {
      _logBreadcrumb('AiService.dailyBriefing failed: $e');
      debugPrint('AI dailyBriefing failed: $e');
      return '';
    }
  }

  TaskPriority _parsePriority(String? p) => aiParsePriority(p);

  TaskCategory _parseCategory(String? c) => aiParseCategory(c);
}
