import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Whether [e] looks like overload / rate limit (safe to retry a few times).
bool isTransientGeminiFailure(Object e) {
  if (e is InvalidApiKey || e is UnsupportedUserLocation) return false;
  if (e is! GenerativeAIException) return false;
  final m = e.toString();
  return m.contains('503') ||
      m.contains('429') ||
      m.contains('UNAVAILABLE') ||
      m.contains('RESOURCE_EXHAUSTED') ||
      m.contains('high demand') ||
      m.contains('overloaded') ||
      m.contains('try again later');
}

/// Retries [attempt] on transient Gemini API failures (503, 429, etc.).
Future<T> withGeminiRetry<T>(
  Future<T> Function() attempt, {
  Duration perAttemptTimeout = const Duration(seconds: 120),
  int maxAttempts = 4,
}) async {
  final backoffBeforeMs = <int>[600, 1800, 4000];
  for (var i = 0; i < maxAttempts; i++) {
    if (i > 0) {
      await Future<void>.delayed(Duration(milliseconds: backoffBeforeMs[i - 1]));
    }
    try {
      return await attempt().timeout(perAttemptTimeout);
    } catch (e) {
      final retry = isTransientGeminiFailure(e);
      if (retry) {
        debugPrint('Gemini transient error (${i + 1}/$maxAttempts), will retry: $e');
      }
      if (!retry || i == maxAttempts - 1) rethrow;
    }
  }
  throw StateError('withGeminiRetry: unreachable');
}
