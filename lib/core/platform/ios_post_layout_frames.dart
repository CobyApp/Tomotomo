import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/scheduler.dart';

/// Awaits [count] scheduler frame boundaries (each [SchedulerBinding.endOfFrame]).
/// Tied to the render pump, not wall-clock delay.
Future<void> waitSchedulerFrames(int count) async {
  assert(count >= 0);
  for (var i = 0; i < count; i++) {
    await SchedulerBinding.instance.endOfFrame;
  }
}

/// On iOS, waits [frames] extra frames after the current callback so plugin/native
/// work does not run in the same pump as the first shell layout (device EXC_BAD_ACCESS).
/// No-op on Android, desktop, and web.
Future<void> waitIosPostLayoutFrames({int frames = 2}) async {
  if (kIsWeb || !Platform.isIOS) return;
  await waitSchedulerFrames(frames);
}
