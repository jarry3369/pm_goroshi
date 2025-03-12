import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'permission_handler.g.dart';

class AppPermissionHandler {
  /// 필요한 모든 권한 요청
  Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    Map<Permission, PermissionStatus> statuses = {};

    // 카메라 권한
    statuses[Permission.camera] = await Permission.camera.request();

    // 위치 권한
    statuses[Permission.location] = await Permission.location.request();

    return statuses;
  }

  /// 카메라 권한만 요청
  Future<PermissionStatus> requestCameraPermission() async {
    return await Permission.camera.request();
  }

  /// 위치 권한만 요청
  Future<PermissionStatus> requestLocationPermission() async {
    return await Permission.location.request();
  }

  /// 권한 상태 확인
  Future<bool> checkPermission(Permission permission) async {
    return await permission.isGranted;
  }
}

@riverpod
AppPermissionHandler permissionHandler(PermissionHandlerRef ref) {
  return AppPermissionHandler();
}
