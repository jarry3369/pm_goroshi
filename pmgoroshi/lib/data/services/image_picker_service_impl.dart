import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pmgoroshi/core/permissions/permission_handler.dart';
import 'package:pmgoroshi/domain/services/image_picker_service.dart';

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
  Future<String?> pickImageFromCamera() async {
    final hasPermission = await permissionHandler.checkPermission(
      Permission.camera,
    );

    if (!hasPermission) {
      final status = await permissionHandler.requestCameraPermission();
      if (status != PermissionStatus.granted) {
        return null;
      }
    }

    final result = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    return result?.path;
  }
}

@riverpod
ImagePickerService imagePickerService(ImagePickerServiceRef ref) {
  final permissionHandler = ref.watch(permissionHandlerProvider);
  return ImagePickerServiceImpl(permissionHandler: permissionHandler);
}
