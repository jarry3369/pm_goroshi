import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pmgoroshi/domain/entities/scan_result.dart';
import 'package:pmgoroshi/data/services/qr_scanner_service_impl.dart';
import 'package:pmgoroshi/presentation/pages/qr_scan/qr_scan_controller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pmgoroshi/core/permissions/permission_handler.dart';
import 'package:pmgoroshi/data/services/location_service.dart';

class QRScanPage extends ConsumerStatefulWidget {
  const QRScanPage({super.key});

  @override
  ConsumerState<QRScanPage> createState() => _QRScanPageState();
}

class _QRScanPageState extends ConsumerState<QRScanPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 권한 체크 후 스캐너 초기화
    _checkPermissionsAndInitialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 앱이 백그라운드에서 포그라운드로 돌아올 때 스캐너 재시작
    if (state == AppLifecycleState.resumed) {
      _checkPermissionsAndInitialize();
    }
  }

  Future<void> _checkPermissionsAndInitialize() async {
    final permissionHandler = ref.read(permissionHandlerProvider);

    // 카메라 권한 확인
    final hasCameraPermission = await permissionHandler.checkPermission(
      Permission.camera,
    );

    // 위치 권한도 함께 확인
    final hasLocationPermission = await permissionHandler.checkPermission(
      Permission.location,
    );

    // 위치 권한이 없으면 요청
    if (!hasLocationPermission) {
      await permissionHandler.requestLocationPermission();
    }

    if (hasCameraPermission) {
      // 권한이 있을 경우 스캐너 초기화
      ref.read(qRScanControllerProvider.notifier).initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      qrScannerServiceProvider.select((service) => service.scanResultStream),
      (previous, next) {
        next.listen((result) {
          if (result != null) {
            // QR 스캔 결과가 있을 경우 다음 화면으로 이동
            context.push('/form', extra: result.qrData);
          }
        });
      },
    );

    return Scaffold(
      appBar: AppBar(title: const Text('QR 코드 스캔'), centerTitle: true),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildScannerView()),
            const SizedBox(height: 20),
            _buildScanInstructions(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerView() {
    final scannerService = ref.watch(qrScannerServiceProvider);
    final scanControllerState = ref.watch(qRScanControllerProvider);

    return scanControllerState.when(
      data:
          (_) => Stack(
            alignment: Alignment.center,
            children: [
              // QR 스캐너 카메라 뷰
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: MobileScanner(
                    controller: MobileScannerController(
                      detectionSpeed: DetectionSpeed.normal,
                      facing: CameraFacing.back,
                    ),
                    onDetect: (capture) {
                      final barcodes = capture.barcodes;
                      if (barcodes.isNotEmpty &&
                          barcodes.first.rawValue != null) {
                        final qrData = barcodes.first.rawValue!;
                        final result = ScanResult(
                          qrData: qrData,
                          scanTime: DateTime.now(),
                        );

                        // 스캐너 중지 후 다음 화면으로 이동
                        scannerService.stopScanner();
                        context.push('/form', extra: qrData);
                      }
                    },
                  ),
                ),
              ),

              // QR 스캔 오버레이
              Positioned.fill(
                child: CustomPaint(painter: ScannerOverlayPainter()),
              ),
            ],
          ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                Text(
                  '카메라 접근 권한이 필요합니다',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    await openAppSettings();
                    _checkPermissionsAndInitialize();
                  },
                  child: const Text('권한 설정하기'),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildScanInstructions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            'QR 코드를 프레임 안에 위치시키세요',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '자동으로 스캔됩니다',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// QR 스캔 오버레이 페인터
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final centerX = width / 2;
    final centerY = height / 2;

    // 스캔 영역 크기
    final scanAreaSize = width * 0.7;

    // 스캔 영역 경계
    final scanRect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: scanAreaSize,
      height: scanAreaSize,
    );

    // 배경 반투명 검정
    final backgroundPaint =
        Paint()
          ..color = Colors.black.withOpacity(0.5)
          ..style = PaintingStyle.fill;

    // 스캔 영역 경계선
    final borderPaint =
        Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;

    // 전체 화면 패스
    final backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, width, height));

    // 스캔 영역 패스
    final holePath = Path()..addRect(scanRect);

    // 스캔 영역을 제외한 배경만 그림
    final finalPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      holePath,
    );

    canvas.drawPath(finalPath, backgroundPaint);
    canvas.drawRect(scanRect, borderPaint);

    // 모서리 표시
    final cornerSize = scanAreaSize * 0.1;

    // 왼쪽 상단
    canvas.drawLine(
      Offset(scanRect.left, scanRect.top + cornerSize),
      Offset(scanRect.left, scanRect.top),
      borderPaint,
    );
    canvas.drawLine(
      Offset(scanRect.left, scanRect.top),
      Offset(scanRect.left + cornerSize, scanRect.top),
      borderPaint,
    );

    // 오른쪽 상단
    canvas.drawLine(
      Offset(scanRect.right - cornerSize, scanRect.top),
      Offset(scanRect.right, scanRect.top),
      borderPaint,
    );
    canvas.drawLine(
      Offset(scanRect.right, scanRect.top),
      Offset(scanRect.right, scanRect.top + cornerSize),
      borderPaint,
    );

    // 왼쪽 하단
    canvas.drawLine(
      Offset(scanRect.left, scanRect.bottom - cornerSize),
      Offset(scanRect.left, scanRect.bottom),
      borderPaint,
    );
    canvas.drawLine(
      Offset(scanRect.left, scanRect.bottom),
      Offset(scanRect.left + cornerSize, scanRect.bottom),
      borderPaint,
    );

    // 오른쪽 하단
    canvas.drawLine(
      Offset(scanRect.right - cornerSize, scanRect.bottom),
      Offset(scanRect.right, scanRect.bottom),
      borderPaint,
    );
    canvas.drawLine(
      Offset(scanRect.right, scanRect.bottom),
      Offset(scanRect.right, scanRect.bottom - cornerSize),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
