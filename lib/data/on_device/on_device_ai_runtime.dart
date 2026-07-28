abstract interface class OnDeviceAiRuntime {
  Future<void> initialize();
  Future<bool> isModelInstalled();
  Future<void> installModel({
    required void Function(double progress) onProgress,
    void Function()? onVerifying,
  });
  void cancelInstall();

  /// Wipes all download bookkeeping (queued/failed tasks, records, partial
  /// data) so the next [installModel] starts from a clean slate. Used to
  /// recover from a download that failed or got stuck.
  Future<void> resetDownloadState();
  Future<void> deleteModel();
  Future<String> generateText({
    required String systemInstruction,
    required String prompt,
    double temperature = 0.2,
    int maxTokens = 4096,
  });
  String? get activeBackend;
  Future<void> dispose();
}
