abstract interface class OnDeviceAiRuntime {
  Future<void> initialize();
  Future<bool> isModelInstalled();
  Future<void> installModel({
    required void Function(double progress) onProgress,
  });
  void cancelInstall();
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
