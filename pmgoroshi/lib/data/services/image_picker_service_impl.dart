import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pmgoroshi/core/permissions/permission_handler.dart';
import 'package:pmgoroshi/domain/services/image_picker_service.dart';
import 'package:flutter/foundation.dart';

part 'image_picker_service_impl.g.dart';

class ImagePickerServiceImpl implements ImagePickerService {
  ImagePickerServiceImpl({required this.permissionHandler});

  final AppPermissionHandler permissionHandler;
  final ImagePicker _picker = ImagePicker();

  @override
  Future<String?> pickImageFromGallery() async {
    final result = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    return result?.path;
  }

  @override
  Future<List<String>> pickMultipleImagesFromGallery() async {
    final result = await _picker.pickMultiImage(
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    // null 안전 처리 및 경로 목록 반환
    return result.map((image) => image.path).toList();
  }

  @override
  Future<String?> pickImageFromCamera() async {
    try {
      debugPrint('카메라로 사진 촬영 시도');
      final result = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (result == null) {
        debugPrint('사용자가 사진 촬영을 취소함');
        return null;
      }

      debugPrint('사진 촬영 성공: ${result.path}');
      return result.path;
    } catch (e) {
      debugPrint('카메라 에러 발생: $e');
      // 실제 카메라 접근 실패시에만 권한 관련 메시지 표시
      if (e.toString().contains('camera_access_denied')) {
        throw '카메라를 사용할 수 없습니다. 설정에서 권한을 허용해주세요.';
      }
      rethrow;
    }
  }
}

@riverpod
ImagePickerService imagePickerService(ImagePickerServiceRef ref) {
  final permissionHandler = ref.watch(permissionHandlerProvider);
  return ImagePickerServiceImpl(permissionHandler: permissionHandler);
}
