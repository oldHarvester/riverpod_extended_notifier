import 'package:flutter/scheduler.dart';

abstract class CleverWidgetsBinding {
  static void executeFrame(VoidCallback callback) {
    final binding = SchedulerBinding.instance;
    if (binding.schedulerPhase != SchedulerPhase.idle ||
        binding.hasScheduledFrame) {
      binding.addPostFrameCallback((_) {
        callback();
      });
    } else {
      callback();
    }
  }
}
