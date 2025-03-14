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

  /// 앱 시작 시 위치 권한 요청
  Future<void> requestInitialLocationPermission() async {
    // 위치 권한 확인
    final status = await Permission.location.status;

    // 권한이 없는 경우에만 요청
    if (status.isDenied) {
      await Permission.location.request();
    }
  }
}

@riverpod
AppPermissionHandler permissionHandler(PermissionHandlerRef ref) {
  return AppPermissionHandler();
}
