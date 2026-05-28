import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/pomodoro_controller.dart';
import '../utils/animations.dart';
import '../utils/app_colors.dart';

class PomodoroView extends StatefulWidget {
  final String taskTitle;

  const PomodoroView({super.key, required this.taskTitle});

  @override
  State<PomodoroView> createState() => _PomodoroViewState();
}

class _PomodoroViewState extends State<PomodoroView> {
  late final PomodoroController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(PomodoroController());
    controller.startFor(widget.taskTitle);
  }

  @override
  void dispose() {
    Get.delete<PomodoroController>(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Focus Timer', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Get.dialog(AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Stop Pomodoro?'),
              content: const Text('This will reset your current session and all progress.'),
              actions: [
                TextButton(onPressed: () => Get.back(), child: const Text('Continue')),
                TextButton(
                  onPressed: () {
                    controller.stop();
                    Get.back();
                    Get.back();
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                  child: const Text('Stop & Exit'),
                ),
              ],
            ));
          },
        ),
      ),
      body: Obx(() {
        final isBreak = controller.isBreak.value;
        final primaryColor = isBreak ? const Color(0xFF22C55E) : context.gradientPrimary;
        final secondaryColor = isBreak ? const Color(0xFF16A34A) : context.gradientSecondary;

        return Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Phase label
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isBreak ? 'Break Time' : 'Focus Session',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: primaryColor),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Task name
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      controller.currentTaskTitle.value,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Circular timer
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: controller.progress),
                    duration: kAnimSlow,
                    curve: Curves.easeInOut,
                    builder: (context, value, _) {
                      return SizedBox(
                        width: 220,
                        height: 220,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox.expand(
                              child: CircularProgressIndicator(
                                value: value,
                                strokeWidth: 10,
                                backgroundColor: primaryColor.withValues(alpha: 0.12),
                                valueColor: AlwaysStoppedAnimation(primaryColor),
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  controller.timeDisplay,
                                  style: TextStyle(
                                    fontSize: 52,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -2,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  isBreak ? 'rest' : 'focus',
                                  style: TextStyle(fontSize: 14, color: primaryColor, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 48),

                  // Sessions completed badge
                  if (controller.sessionsCompleted.value > 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '${controller.sessionsCompleted.value} session${controller.sessionsCompleted.value == 1 ? '' : 's'} completed',
                          style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 48),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Reset
                  GestureDetector(
                    onTap: controller.reset,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.replay_rounded, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                  ),
                  const SizedBox(width: 24),

                  // Play/Pause
                  GestureDetector(
                    onTap: controller.togglePause,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [primaryColor, secondaryColor], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: primaryColor.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))],
                      ),
                      child: Icon(
                        controller.isRunning.value ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),

                  // Skip
                  GestureDetector(
                    onTap: () {
                      controller.cancelTimer();
                      if (controller.isBreak.value) {
                        controller.isBreak.value = false;
                        controller.secondsLeft.value = PomodoroController.workSeconds;
                      } else {
                        controller.sessionsCompleted.value++;
                        controller.isBreak.value = true;
                        controller.secondsLeft.value = PomodoroController.shortBreakSeconds;
                      }
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.skip_next_rounded, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
