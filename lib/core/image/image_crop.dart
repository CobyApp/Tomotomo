import 'package:image_cropper/image_cropper.dart';

/// Opens the native crop UI on [sourcePath]. Returns the cropped file path, or
/// null if the user cancelled. [square] locks a 1:1 ratio (avatars); otherwise
/// the user can freely size/crop (chat backgrounds).
Future<String?> cropImagePath(String sourcePath, {bool square = false}) async {
  final cropped = await ImageCropper().cropImage(
    sourcePath: sourcePath,
    aspectRatio: square
        ? const CropAspectRatio(ratioX: 1, ratioY: 1)
        : null,
    uiSettings: [
      IOSUiSettings(
        aspectRatioLockEnabled: square,
        resetAspectRatioEnabled: !square,
        rotateButtonsHidden: false,
      ),
      AndroidUiSettings(
        lockAspectRatio: square,
        hideBottomControls: false,
      ),
    ],
  );
  return cropped?.path;
}
