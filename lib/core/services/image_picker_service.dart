import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';
import 'app_logger.dart';

@singleton
class ImagePickerService {
  final ImagePicker _picker = ImagePicker();
  final AppLogger _logger;

  ImagePickerService(this._logger);

  /// Pick an image file from the device Gallery
  Future<File?> pickImageFromGallery({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    try {
      _logger.d('ImagePicker: Picking image from gallery');
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );

      if (pickedFile != null) {
        _logger.d('ImagePicker: Image selected -> ${pickedFile.path}');
        return File(pickedFile.path);
      }
      _logger.d('ImagePicker: No image selected');
      return null;
    } catch (e, stackTrace) {
      _logger.e('ImagePickerService gallery selection failed', e, stackTrace);
      return null;
    }
  }

  /// Pick an image file directly from the device Camera
  Future<File?> pickImageFromCamera({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    try {
      _logger.d('ImagePicker: Picking image from camera');
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );

      if (pickedFile != null) {
        _logger.d('ImagePicker: Image captured -> ${pickedFile.path}');
        return File(pickedFile.path);
      }
      _logger.d('ImagePicker: No image captured');
      return null;
    } catch (e, stackTrace) {
      _logger.e('ImagePickerService camera capture failed', e, stackTrace);
      return null;
    }
  }
}
