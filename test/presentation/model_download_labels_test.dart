import 'package:aichat/data/on_device/on_device_model_config.dart';
import 'package:aichat/presentation/on_device/model_download_labels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the total matches the size the model actually is, in GB', () {
    // 2_588_147_712 bytes is 2.59 GB decimal. Dividing by 1024³ and labelling it
    // "GB" showed 2.4GB — less than the file's own documented example of 2.6GB.
    expect(OnDeviceModelConfig.byteCount, 2588147712);
    expect(modelDownloadSizeLabel(0), '0.0 / 2.6GB');
    expect(modelDownloadSizeLabel(1), '2.6 / 2.6GB');
  });

  test('progress is clamped and formatted to one decimal', () {
    expect(modelDownloadSizeLabel(0.5), '1.3 / 2.6GB');
    expect(modelDownloadSizeLabel(-1), '0.0 / 2.6GB');
    expect(modelDownloadSizeLabel(2), '2.6 / 2.6GB');
  });
}
