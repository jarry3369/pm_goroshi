import 'dart:async';
import 'package:flutter/services.dart';
import 'package:riverpod/riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pmgoroshi/domain/entities/scan_result.dart';
import 'package:pmgoroshi/domain/services/qr_scanner_service.dart';
import 'package:pmgoroshi/core/permissions/permission_handler.dart';
import 'package:permission_handler/permission_handler.dart';

part 'qr_scanner_service_impl.g.dart';

class QRScannerServiceImpl implements QRScannerService {
  QRScannerServiceImpl({required this.permissionHandler}) {
    _init();
  }

  final AppPermissionHandler permissionHandler;
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  final _scanResultController = StreamController<ScanResult?>.broadcast();
  bool _isScanning = false;

  void _init() {
    _controller.barcodes.listen((capture) {
      if (capture.barcodes.isNotEmpty &&
          capture.barcodes.first.rawValue != null) {
        final qrData = capture.barcodes.first.rawValue!;

        // QR 코드 결과 처리
        final result = ScanResult(qrData: qrData, scanTime: DateTime.now());

        _scanResultController.add(result);
      }
    });
  }

  @override
  Stream<ScanResult?> get scanResultStream => _scanResultController.stream;

  @override
  Future<void> startScanner() async {
    final hasPermission = await permissionHandler.checkPermission(
      Permission.camera,
    );

    if (!hasPermission) {
      final status = await permissionHandler.requestCameraPermission();
      if (status != PermissionStatus.granted) {
        throw PlatformException(
          code: 'PERMISSION_DENIED',
          message: '카메라 권한이 필요합니다',
        );
      }
    }

    await _controller.start();
    _isScanning = true;
  }

  @override
  Future<void> stopScanner() async {
    await _controller.stop();
    _isScanning = false;
  }

  @override
  Future<void> toggleScanner() async {
    if (_isScanning) {
      await stopScanner();
    } else {
      await startScanner();
    }
  }

  @override
  bool get isScanning => _isScanning;

  void dispose() {
    _controller.dispose();
    _scanResultController.close();
  }
}

@riverpod
QRScannerService qrScannerService(Ref ref) {
  final permissionHandler = ref.watch(permissionHandlerProvider);

  final service = QRScannerServiceImpl(permissionHandler: permissionHandler);

  ref.onDispose(() {
    service.dispose();
  });

  return service;
}
