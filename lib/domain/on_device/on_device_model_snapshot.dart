enum OnDeviceModelPhase { checking, notInstalled, downloading, ready, error }

class OnDeviceModelSnapshot {
  const OnDeviceModelSnapshot({
    required this.phase,
    this.progress = 0,
    this.backend,
    this.errorMessage,
  });

  final OnDeviceModelPhase phase;
  final double progress;
  final String? backend;
  final String? errorMessage;

  bool get isReady => phase == OnDeviceModelPhase.ready;

  OnDeviceModelSnapshot copyWith({
    OnDeviceModelPhase? phase,
    double? progress,
    String? backend,
    String? errorMessage,
    bool clearError = false,
  }) {
    return OnDeviceModelSnapshot(
      phase: phase ?? this.phase,
      progress: progress ?? this.progress,
      backend: backend ?? this.backend,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
