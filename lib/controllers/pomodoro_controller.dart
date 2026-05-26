import 'dart:async';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class PomodoroController extends GetxController {
  static const int workSeconds = 25 * 60;
  static const int shortBreakSeconds = 5 * 60;

  static const _keySecondsLeft = 'pomodoro_seconds_left';
  static const _keyIsBreak = 'pomodoro_is_break';
  static const _keySessions = 'pomodoro_sessions';
  static const _keyTaskTitle = 'pomodoro_task_title';
  static const _keyTimerStartedAt = 'pomodoro_timer_started_at';

  final secondsLeft = workSeconds.obs;
  final isRunning = false.obs;
  final isBreak = false.obs;
  final sessionsCompleted = 0.obs;
  final currentTaskTitle = ''.obs;

  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    _restoreState();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  Future<void> _restoreState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSeconds = prefs.getInt(_keySecondsLeft);
    if (savedSeconds == null) return;

    secondsLeft.value = savedSeconds;
    isBreak.value = prefs.getBool(_keyIsBreak) ?? false;
    sessionsCompleted.value = prefs.getInt(_keySessions) ?? 0;
    currentTaskTitle.value = prefs.getString(_keyTaskTitle) ?? '';

    final startedAt = prefs.getInt(_keyTimerStartedAt);
    if (startedAt != null) {
      final elapsed = DateTime.now().millisecondsSinceEpoch - startedAt;
      final elapsedSeconds = elapsed ~/ 1000;
      secondsLeft.value = (secondsLeft.value - elapsedSeconds).clamp(0, secondsLeft.value);
      if (secondsLeft.value <= 0) {
        _onComplete();
        return;
      }
      _start();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySecondsLeft, secondsLeft.value);
    await prefs.setBool(_keyIsBreak, isBreak.value);
    await prefs.setInt(_keySessions, sessionsCompleted.value);
    await prefs.setString(_keyTaskTitle, currentTaskTitle.value);
    if (isRunning.value) {
      await prefs.setInt(_keyTimerStartedAt, DateTime.now().millisecondsSinceEpoch);
    } else {
      await prefs.remove(_keyTimerStartedAt);
    }
  }

  Future<void> _clearPersisted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySecondsLeft);
    await prefs.remove(_keyIsBreak);
    await prefs.remove(_keySessions);
    await prefs.remove(_keyTaskTitle);
    await prefs.remove(_keyTimerStartedAt);
  }

  String get timeDisplay {
    final m = (secondsLeft.value ~/ 60).toString().padLeft(2, '0');
    final s = (secondsLeft.value % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get progress {
    final total = isBreak.value ? shortBreakSeconds : workSeconds;
    return (total - secondsLeft.value) / total;
  }

  void startFor(String taskTitle) {
    currentTaskTitle.value = taskTitle;
    isBreak.value = false;
    secondsLeft.value = workSeconds;
    _start();
    _persist();
  }

  void togglePause() {
    if (isRunning.value) {
      _timer?.cancel();
      isRunning.value = false;
    } else {
      _start();
    }
    _persist();
  }

  void reset() {
    _timer?.cancel();
    isRunning.value = false;
    secondsLeft.value = isBreak.value ? shortBreakSeconds : workSeconds;
    _persist();
  }

  void cancelTimer() {
    _timer?.cancel();
    _timer = null;
    isRunning.value = false;
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    isRunning.value = false;
    isBreak.value = false;
    secondsLeft.value = workSeconds;
    sessionsCompleted.value = 0;
    currentTaskTitle.value = '';
    _clearPersisted();
  }

  void _start() {
    isRunning.value = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (secondsLeft.value > 0) {
        secondsLeft.value--;
      } else {
        _onComplete();
      }
    });
  }

  void _onComplete() {
    _timer?.cancel();
    isRunning.value = false;
    if (!isBreak.value) {
      sessionsCompleted.value++;
      isBreak.value = true;
      secondsLeft.value = shortBreakSeconds;
      NotificationService().showInstant(
        id: 99999,
        title: 'Pomodoro Complete!',
        body: '${sessionsCompleted.value} session${sessionsCompleted.value == 1 ? '' : 's'} done. Time for a 5-min break.',
      );
    } else {
      isBreak.value = false;
      secondsLeft.value = workSeconds;
      NotificationService().showInstant(
        id: 99998,
        title: 'Break Over!',
        body: 'Ready for your next focus session?',
      );
    }
    _persist();
  }
}
