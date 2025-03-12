import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pmgoroshi/domain/entities/scan_result.dart';
import 'package:pmgoroshi/data/services/qr_scanner_service_impl.dart';

part 'qr_scan_controller.g.dart';

@riverpod
class QRScanController extends _$QRScanController {
  StreamSubscription<ScanResult?>? _subscription;

  @override
  FutureOr<void> build() {
    ref.onDispose(() {
      _subscription?.cancel();
    });
  }

  void initialize() async {
    final scannerService = ref.read(qrScannerServiceProvider);

    // 스캔 결과 구독
    _subscription = scannerService.scanResultStream.listen((result) {
      if (result != null) {
        handleScanResult(result);
      }
    });

    // 스캐너 시작
    try {
      await scannerService.startScanner();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
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
}
