import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Shared animation constants
const kAnimFast = Duration(milliseconds: 200);
const kAnimNormal = Duration(milliseconds: 350);
const kAnimSlow = Duration(milliseconds: 500);
const kCurveSpring = Curves.easeOutBack;
const kCurveBounce = Curves.elasticOut;
const kCurveSmooth = Curves.easeInOutCubic;

Duration animDuration(BuildContext context, {required int ms}) {
  if (MediaQuery.of(context).disableAnimations) return Duration.zero;
  return Duration(milliseconds: ms);
}

extension AnimatedContext on Widget {
  Widget animateIfEnabled(BuildContext context, {
    int delayMs = 0,
    int durationMs = 350,
    bool fade = false,
    bool slideY = false,
    bool slideX = false,
    bool scale = false,
  }) {
    if (MediaQuery.of(context).disableAnimations) return this;
    var a = animate(delay: Duration(milliseconds: delayMs));
    if (fade) a = a.fadeIn(duration: Duration(milliseconds: durationMs));
    if (slideY) a = a.slideY(begin: 0.08, duration: Duration(milliseconds: durationMs));
    if (slideX) a = a.slideX(begin: 0.08, duration: Duration(milliseconds: durationMs));
    if (scale) a = a.scale(begin: const Offset(0.95, 0.95), duration: Duration(milliseconds: durationMs));
    return a;
  }
}

Widget fadeSlideIn(BuildContext context, Widget child, {int delayMs = 0}) {
  return child.animateIfEnabled(context, delayMs: delayMs, fade: true, slideY: true);
}

Widget scaleIn(BuildContext context, Widget child, {int delayMs = 0}) {
  return child.animateIfEnabled(context, delayMs: delayMs, fade: true, scale: true);
}
