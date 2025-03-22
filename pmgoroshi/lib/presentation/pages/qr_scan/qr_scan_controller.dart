import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pmgoroshi/domain/entities/scan_result.dart';
import 'package:pmgoroshi/data/services/qr_scanner_service_impl.dart';
import 'package:pmgoroshi/domain/services/qr_scanner_service.dart';

part 'qr_scan_controller.g.dart';

// 스캔 결과를 페이지로 전달하기 위한 스트림 컨트롤러
final _scanResultForRouting = StreamController<ScanResult>.broadcast();

// 스캔 결과 스트림 Provider (Riverpod의 일반 Provider 사용)
final scanResultForRoutingProvider = StreamProvider<ScanResult>((ref) {
  return _scanResultForRouting.stream;
});

@riverpod
class QRScanController extends _$QRScanController {
  StreamSubscription<ScanResult?>? _subscription;
  late QRScannerService _scannerService;
  bool _processingResult = false; // 결과 처리 중 플래그 추가

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
    _processingResult = false; // 초기화 시 처리 플래그 리셋

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
          if (result != null && !_processingResult) {
            handleScanResult(result);
          } else if (_processingResult) {
            debugPrint('QRScanController - 이미 처리 중인 결과가 있어 무시됨');
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
    // 이미 처리 중이면 중복 처리 방지
    if (_processingResult) {
      debugPrint('QRScanController - 이미 다른 QR 처리 중이므로 무시합니다.');
      return;
    }

    // 처리 중 플래그 설정
    _processingResult = true;

    final scannerService = ref.read(qrScannerServiceProvider);

    debugPrint(
      'QRScanController - handleScanResult: QR 스캔 결과 처리 시작: ${result.qrData}',
    );

    // 스캐너 중지 (연속 스캔 방지)
    try {
      await scannerService.stopScanner();
      debugPrint('QRScanController - handleScanResult: 스캐너 중지 성공');
    } catch (e) {
      debugPrint('QRScanController - handleScanResult: 스캐너 중지 실패: $e');
      _processingResult = false; // 실패 시 플래그 리셋
      return;
    }

    debugPrint('QRScanController - 라우팅을 위해 결과 전달');

    // 스트림에 결과 전달하여 페이지 라우팅 트리거
    _scanResultForRouting.add(result);

    debugPrint('QRScanController - handleScanResult: 라우팅을 위해 결과 스트림에 전달됨');
  }

  /// MobileScanner의 onDetect 콜백에서 직접 감지된 QR 코드를 처리하기 위한 메서드
  void handleRawScanResult(ScanResult result) {
    // 이미 처리 중이면 중복 처리 방지
    if (_processingResult) {
      debugPrint(
        'QRScanController - handleRawScanResult: 이미 다른 QR 처리 중이므로 무시합니다.',
      );
      return;
    }

    // 처리 중 플래그 설정
    _processingResult = true;

    debugPrint(
      'QRScanController - handleRawScanResult: 직접 감지된 QR 코드 처리: ${result.qrData}',
    );

    // 지연 없이 바로 결과 스트림에 전달 (라우팅 트리거)
    _scanResultForRouting.add(result);

    debugPrint('QRScanController - handleRawScanResult: 결과 스트림으로 직접 전달됨');
  }

  /// 스캐너 상태 초기화
  void resetScanner() async {
    debugPrint('QRScanController - resetScanner: 스캐너 상태 초기화');
    _processingResult = false; // 처리 플래그 리셋

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
