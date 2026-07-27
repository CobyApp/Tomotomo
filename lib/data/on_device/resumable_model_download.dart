import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:path_provider/path_provider.dart';

import 'on_device_model_config.dart';

/// Downloads the on-device model file with REAL pause/resume support.
///
/// Why this exists instead of flutter_gemma's built-in network installer:
/// that installer disables HTTP-range resume for any `huggingface.co` URL
/// (a blanket weak-ETag heuristic). Our model file is actually served with a
/// strong ETag and `Accept-Ranges: bytes`, so resume works fine for it —
/// and without resume the 2.59GB download restarts from 0% every time iOS
/// drops the transfer (user force-quits the app, the OS reclaims the session,
/// network switches). background_downloader persists resume data across app
/// kills, so with `allowPause: true` the download continues where it left off.
///
/// The finished file is handed to flutter_gemma via `fromFile()`, which is a
/// pure registration step (no copy), so the engine loads it as usual.
class ResumableModelDownload {
  /// Own group so our notification config and queries never collide with
  /// flutter_gemma's internal `smart_downloads` group.
  static const group = 'tomotomo_model';

  /// Stable task id tied to the MODEL VERSION, never to an absolute path.
  /// (Container paths change across reinstalls/updates on iOS; a path-derived
  /// id would orphan an in-flight download and force a restart from 0%.)
  static const _taskId = 'tomotomo-model-gemma4-e2b';

  /// Subdirectory under Documents holding the downloaded artifact.
  static const _subDirectory = 'models';

  StreamSubscription<TaskUpdate>? _sub;
  Completer<void>? _completer;
  bool _canceled = false;

  /// Absolute path the artifact is downloaded to.
  static Future<String> filePath() async {
    final docs = await getApplicationDocumentsDirectory();
    return '${docs.path}/$_subDirectory/${OnDeviceModelConfig.fileName}';
  }

  DownloadTask _buildTask() => DownloadTask(
    taskId: _taskId,
    url: OnDeviceModelConfig.downloadUri.toString(),
    filename: OnDeviceModelConfig.fileName,
    directory: _subDirectory,
    baseDirectory: BaseDirectory.applicationDocuments,
    group: group,
    updates: Updates.statusAndProgress,
    // The whole point: lets the OS pause/resume instead of restarting, and
    // lets us resume a transfer the OS killed while the app was gone.
    allowPause: true,
    retries: 5,
  );

  /// Downloads the model (resuming when possible) and returns its path.
  ///
  /// [onProgress] receives 0.0–1.0. Throws on failure or cancellation.
  Future<String> download({
    required void Function(double progress) onProgress,
  }) async {
    _canceled = false;
    final target = await filePath();

    // A fully downloaded artifact may already be sitting there (e.g. we
    // finished but the registration step failed last run).
    final existing = File(target);
    if (await existing.exists() &&
        await existing.length() == OnDeviceModelConfig.byteCount) {
      onProgress(1);
      return target;
    }

    // Track tasks so resume data + status survive an app kill.
    try {
      await FileDownloader().trackTasksInGroup(group);
    } catch (_) {}

    final completer = Completer<void>();
    _completer = completer;

    await _sub?.cancel();
    _sub = FileDownloader().updates.listen((update) {
      if (update.task.taskId != _taskId) return;
      if (update is TaskProgressUpdate) {
        final p = update.progress;
        // background_downloader uses negative sentinels for "unknown".
        if (p >= 0) onProgress(p.clamp(0.0, 1.0));
      } else if (update is TaskStatusUpdate) {
        switch (update.status) {
          case TaskStatus.complete:
            if (!completer.isCompleted) completer.complete();
          case TaskStatus.canceled:
            if (!completer.isCompleted) {
              completer.completeError(
                StateError('대화 엔진 다운로드가 취소되었습니다.'),
              );
            }
          case TaskStatus.failed:
            if (!completer.isCompleted) {
              completer.completeError(
                StateError(
                  '대화 엔진 다운로드에 실패했습니다: ${update.exception?.description ?? ''}',
                ),
              );
            }
          case TaskStatus.paused:
            // The OS paused us (backgrounded / lost WiFi). Ask to continue;
            // if resume isn't feasible the task restarts on its own.
            unawaited(_resumeIfPossible());
          case TaskStatus.enqueued:
          case TaskStatus.running:
          case TaskStatus.notFound:
          case TaskStatus.waitingToRetry:
            break;
        }
      }
    });

    try {
      await _startOrAttach();
      await completer.future;
    } finally {
      await _sub?.cancel();
      _sub = null;
      _completer = null;
    }

    final file = File(target);
    if (!await file.exists() ||
        await file.length() != OnDeviceModelConfig.byteCount) {
      throw const FormatException('다운로드한 대화 엔진 파일이 올바르지 않습니다.');
    }
    return target;
  }

  /// Attaches to an in-flight task, resumes a paused/interrupted one, or
  /// enqueues a fresh download — in that order of preference.
  Future<void> _startOrAttach() async {
    // 1. Already running (app was backgrounded, or relaunched while the OS
    //    kept the transfer alive) — the listener above will pick it up.
    final live = await FileDownloader().taskForId(_taskId);
    if (live != null) return;

    // 2. Interrupted earlier: resume from the partial bytes if we can.
    try {
      final record = await FileDownloader().database.recordForId(_taskId);
      final task = record?.task;
      if (task is DownloadTask &&
          (record!.status == TaskStatus.paused ||
              record.status == TaskStatus.failed)) {
        if (await FileDownloader().resume(task)) return;
      }
    } catch (_) {
      // Fall through to a fresh enqueue.
    }

    // 3. Nothing to continue — start clean.
    if (!await FileDownloader().enqueue(_buildTask())) {
      throw StateError('대화 엔진 다운로드를 시작하지 못했습니다.');
    }
  }

  Future<void> _resumeIfPossible() async {
    if (_canceled) return;
    try {
      final record = await FileDownloader().database.recordForId(_taskId);
      final task = record?.task;
      if (task is DownloadTask) await FileDownloader().resume(task);
    } catch (_) {}
  }

  /// Cancels the in-flight download and drops its partial data.
  Future<void> cancel() async {
    _canceled = true;
    try {
      await FileDownloader().cancelTaskWithId(_taskId);
    } catch (_) {}
    final completer = _completer;
    if (completer != null && !completer.isCompleted) {
      completer.completeError(StateError('대화 엔진 다운로드가 취소되었습니다.'));
    }
  }

  /// Clears task records and any partial/complete artifact on disk.
  Future<void> clear() async {
    try {
      await FileDownloader().cancelTaskWithId(_taskId);
    } catch (_) {}
    try {
      await FileDownloader().database.deleteRecordWithId(_taskId);
    } catch (_) {}
    try {
      final file = File(await filePath());
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
