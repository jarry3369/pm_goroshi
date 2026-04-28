import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
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
    autoStart: false,
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

  MobileScannerController get controller => _controller;

  Future<bool> startScan() async {
    // 이미 스캔 중이면 재시작할 필요 없음
    if (_isScanning) {
      final scannerState = _controller.value;
      if (scannerState.isRunning && scannerState.error == null) {
        return true;
      }

      _isScanning = false;
    }

    // 권한 체크
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

    try {
      await _controller.start();
    } on MobileScannerException catch (e) {
      _isScanning = false;
      await stopScan();
      throw PlatformException(
        code: e.errorCode.name,
        message: e.errorDetails?.message ?? e.errorCode.message,
        details: e.toString(),
      );
    }

    final scannerState = _controller.value;
    debugPrint(
      'QRScannerService - started: '
      'isInitialized=${scannerState.isInitialized}, '
      'isRunning=${scannerState.isRunning}, '
      'size=${scannerState.size}, '
      'cameraDirection=${scannerState.cameraDirection}, '
      'availableCameras=${scannerState.availableCameras}, '
      'error=${scannerState.error}',
    );
    final scannerError = scannerState.error;
    if (!scannerState.isRunning ||
        scannerState.size.isEmpty ||
        scannerError != null) {
      _isScanning = false;
      await _controller.stop();
      throw PlatformException(
        code:
            scannerError?.errorCode.name ??
            (scannerState.size.isEmpty
                ? 'SCANNER_EMPTY_PREVIEW'
                : 'SCANNER_NOT_RUNNING'),
        message:
            scannerError?.errorDetails?.message ??
            scannerError?.errorCode.message ??
            (scannerState.size.isEmpty
                ? '카메라는 열렸지만 프리뷰 크기를 가져오지 못했습니다.'
                : '카메라를 시작하지 못했습니다.'),
        details: scannerError?.toString(),
      );
    }

    _isScanning = true;
    return true;
  }

  Future<bool> stopScan() async {
    try {
      await _controller.stop();
      _isScanning = false;
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> startScanner() async {
    final started = await startScan();
    if (!started) {
      throw PlatformException(
        code: 'SCANNER_START_FAILED',
        message: 'QR scanner could not be started',
      );
    }
  }

  @override
  Future<void> stopScanner() async {
    await stopScan();
  }

  @override
  Future<void> toggleScanner() async {
    if (_isScanning) {
      await stopScan();
    } else {
      await startScan();
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
