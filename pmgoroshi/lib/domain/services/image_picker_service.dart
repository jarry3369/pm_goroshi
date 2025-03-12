import 'package:riverpod_annotation/riverpod_annotation.dart';

abstract class ImagePickerService {
  Future<String?> pickImageFromGallery();
  Future<String?> pickImageFromCamera();
}
