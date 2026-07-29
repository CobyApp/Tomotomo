import '../../data/on_device/on_device_model_config.dart';

/// "1.2 / 2.6GB" — concrete downloaded/total size for the model download.
///
/// A bare percentage on a ~2.6GB download looks frozen for minutes at a time;
/// showing real megabytes moving is what tells the user it is still working.
String modelDownloadSizeLabel(double progress) {
  const total = OnDeviceModelConfig.byteCount;
  final done = (total * progress.clamp(0.0, 1.0)).round();
  return '${_gb(done)} / ${_gb(total)}GB';
}

/// Decimal GB, the unit iOS and the App Store use for download sizes.
///
/// Dividing by 1024³ and calling the result "GB" understated a 2.59 GB model as
/// "2.4GB" — contradicting this file's own documented example and making the
/// download look smaller than the figure the user was given.
String _gb(int bytes) => (bytes / (1000 * 1000 * 1000)).toStringAsFixed(1);
