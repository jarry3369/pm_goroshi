import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pmgoroshi/domain/entities/scan_result.dart';
import 'package:pmgoroshi/data/services/qr_scanner_service_impl.dart';
import 'package:pmgoroshi/domain/services/qr_scanner_service.dart';

part 'qr_scan_controller.g.dart';

@riverpod
class QRScanController extends _$QRScanController {
  StreamSubscription<ScanResult?>? _subscription;
  late QRScannerService _scannerService;

  @override
  FutureOr<void> build() {
    _scannerService = ref.read(qrScannerServiceProvider);
    
    ref.onDispose(() {
      _subscription?.cancel();
      debugPrint('QRScanController - onDispose: 구독 취소됨');
    });
    
    return null;
  }

  Future<void> initialize() async {
    debugPrint('QRScanController - 스캐너 초기화 시작');
    
    try {
      // 이미 구독이 있다면 취소
      if (_subscription != null) {
        debugPrint('QRScanController - 기존 스캔 구독 취소');
        await _subscription?.cancel();
        _subscription = null;
      }

      // 스캐너가 실행 중이면 중지
      if (_scannerService.isScanning) {
        debugPrint('QRScanController - 실행 중인 스캐너 중지');
        await _scannerService.stopScanner();
        // 스캐너 중지 후 약간의 지연 시간 추가
        await Future.delayed(const Duration(milliseconds: 300));
      }
      
      debugPrint('QRScanController - 스캐너 시작 시도');
      
      // 스캐너 시작
      try {
        debugPrint('QRScanController - 스캐너 시작');
        await _scannerService.startScanner();
        
        _subscription = _scannerService.scanResultStream.listen((result) {
          debugPrint('QRScanController - QR 스캔 결과: ${result?.qrData}');
          if (result != null) {
            handleScanResult(result);
          }
        });
        
        state = const AsyncValue.data(null);
        debugPrint('QRScanController - 스캐너 시작 성공');
      } catch (e, stack) {
        debugPrint('QRScanController - 스캐너 시작 실패: $e');
        state = AsyncValue.error(e, stack);
      }
    } catch (e) {
      debugPrint('QRScanController - 스캐너 초기화 중 오류: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  void toggleFlash() async {
    // 플래시 토글 기능은 사용성 향상을 위해 추가할 수 있습니다.
    // 여기서는 생략합니다.
  }

  void handleScanResult(ScanResult result) async {
    final scannerService = ref.read(qrScannerServiceProvider);

    // 스캐너 중지 (연속 스캔 방지)
    await scannerService.stopScanner();

    // 결과 처리 및 다음 화면으로 라우팅은 QR 스캔 페이지에서 처리
  }
  
  /// 스캐너 상태 초기화
  void resetScanner() async {
    debugPrint('QRScanController - resetScanner: 스캐너 상태 초기화');
    
    try {
      // 기존 구독 취소
      if (_subscription != null) {
        await _subscription?.cancel();
        _subscription = null;
        debugPrint('QRScanController - 스캔 구독 취소됨');
      }
      
      // 스캐너가 실행 중이면 중지
      if (_scannerService.isScanning) {
        await _scannerService.stopScanner();
        debugPrint('QRScanController - 스캐너 중지됨');
      }
      
    } catch (e) {
      debugPrint('QRScanController - 스캐너 초기화 중 오류: $e');
    }
  }
}
