import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pmgoroshi/domain/entities/scan_result.dart';

abstract class QRScannerService {
  /// QR 코드 스캔 결과를 Stream으로 제공
  Stream<ScanResult?> get scanResultStream;

  /// 스캐너 시작
  Future<void> startScanner();

  /// 스캐너 중지
  Future<void> stopScanner();

  /// 스캐너 토글 (시작/중지)
  Future<void> toggleScanner();

  /// 현재 스캐너 상태
  bool get isScanning;
}
