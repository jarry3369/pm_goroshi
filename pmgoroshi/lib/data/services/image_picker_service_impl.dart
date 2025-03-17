import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:pmgoroshi/core/permissions/permission_handler.dart';
import 'package:pmgoroshi/domain/services/image_picker_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'image_picker_service_impl.g.dart';

class ImagePickerServiceImpl implements ImagePickerService {
  ImagePickerServiceImpl({required this.permissionHandler});

  final AppPermissionHandler permissionHandler;
  final ImagePicker _picker = ImagePicker();

  // 이미지 압축 및 최적화
  Future<String> _compressAndOptimizeImage(String imagePath) async {
    final File imageFile = File(imagePath);
    final int originalSize = await imageFile.length();

    // 임시 디렉토리 가져오기
    final tempDir = await getTemporaryDirectory();
    final targetPath = path.join(
      tempDir.path,
      '${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    // 이미지 크기에 따른 압축 품질 설정
    int quality = 85; // 기본 품질
    if (originalSize > 5 * 1024 * 1024) {
      // 5MB 이상
      quality = 60;
    } else if (originalSize > 2 * 1024 * 1024) {
      // 2MB 이상
      quality = 70;
    }

    try {
      final result = await FlutterImageCompress.compressAndGetFile(
        imagePath,
        targetPath,
        quality: quality,
        format: CompressFormat.jpeg,
        minWidth: 1200,
        minHeight: 1200,
      );

      if (result == null) {
        print('이미지 압축 실패: $imagePath');
        return imagePath; // 압축 실패 시 원본 반환
      }

      final compressedSize = await result.length();
      print(
        '이미지 압축 결과: ${originalSize / 1024}KB -> ${compressedSize / 1024}KB',
      );

      return result.path;
    } catch (e) {
      print('이미지 압축 중 오류 발생: $e');
      return imagePath; // 에러 발생 시 원본 반환
    }
  }

  @override
  Future<String?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (image != null) {
        return await _compressAndOptimizeImage(image.path);
      }
      return null;
    } catch (e) {
      print('갤러리에서 이미지 선택 중 오류 발생: $e');
      return null;
    }
  }

  @override
  Future<List<String>> pickMultipleImagesFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 100,
      );

      if (images.isEmpty) return [];

      final List<String> compressedImages = [];
      for (final image in images) {
        final compressedPath = await _compressAndOptimizeImage(image.path);
        compressedImages.add(compressedPath);
      }

      return compressedImages;
    } catch (e) {
      print('여러 이미지 선택 중 오류 발생: $e');
      return [];
    }
  }

  @override
  Future<String?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
      );

      if (image != null) {
        return await _compressAndOptimizeImage(image.path);
      }
      return null;
    } catch (e) {
      print('카메라로 이미지 촬영 중 오류 발생: $e');
      return null;
    }
  }
}

@riverpod
ImagePickerService imagePickerService(ImagePickerServiceRef ref) {
  final permissionHandler = ref.watch(permissionHandlerProvider);
  return ImagePickerServiceImpl(permissionHandler: permissionHandler);
}
