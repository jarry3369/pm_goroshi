import 'dart:async';
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
import 'package:pmgoroshi/data/services/supabase_service.dart';
import 'package:pmgoroshi/main.dart' show routeObserver;
import 'package:pmgoroshi/presentation/widgets/banner_carousel.dart';
import 'package:pmgoroshi/presentation/controllers/banner_provider.dart';
import 'package:pmgoroshi/presentation/pages/data_form/data_form_page.dart';

class QRScanPage extends ConsumerStatefulWidget {
  const QRScanPage({super.key});

  @override
  ConsumerState<QRScanPage> createState() => _QRScanPageState();
}

class _QRScanPageState extends ConsumerState<QRScanPage>
    with WidgetsBindingObserver, RouteAware {
  bool _isActive = false; // 페이지가 현재 활성 상태인지 추적
  bool _bannerShown = false; // 배너가 이미 표시되었는지 여부

  @override
  void initState() {
    super.initState();
    _isActive = true;
    WidgetsBinding.instance.addObserver(this);
    debugPrint('QRScanPage - initState');

    // 권한 체크 후 스캐너 초기화
    _checkPermissionsAndInitialize();

    // 배너 로딩 및 표시 (지연 실행)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('QRScanPage - 배너 로딩 시작');

      // 데이터 리프레시를 위해 provider를 직접 호출하여 배너 로드
      ref.read(bannerProvider.notifier).refreshBanners().then((_) {
        debugPrint('QRScanPage - 배너 리프레시 완료, 배너 표시 시도');

        // 배너 모달 직접 표시
        final bannersAsync = ref.read(displayableBannersProvider);

        bannersAsync.when(
          data: (banners) {
            debugPrint(
              'QRScanPage - displayableBannersProvider 데이터: ${banners.length}개',
            );
            if (banners.isNotEmpty && !_bannerShown) {
              debugPrint('QRScanPage - 표시할 배너가 있어 모달 표시');

              // 약간의 지연 후 모달 표시 (UI가 완전히 그려진 후)
              Future.delayed(const Duration(milliseconds: 500), () {
                if (_isActive && !_bannerShown) {
                  _bannerShown = true;
                  _showBannerModal(context);
                }
              });
            } else {
              debugPrint(
                'QRScanPage - 표시할 배너가 없거나 이미 표시됨 (isEmpty=${banners.isEmpty}, bannerShown=$_bannerShown)',
              );
            }
          },
          loading: () => debugPrint('QRScanPage - 배너 데이터 로딩 중...'),
          error:
              (error, stack) => debugPrint('QRScanPage - 배너 데이터 로드 오류: $error'),
        );
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    debugPrint('QRScanPage - didChangeDependencies');

    // RouteObserver에 등록
    final route = ModalRoute.of(context);
    if (route != null) {
      routeObserver.subscribe(this, route as PageRoute);
    }

    // 배너가 아직 표시되지 않았다면 표시
    if (!_bannerShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndShowBanner();
      });
    }
  }

  @override
  void dispose() {
    debugPrint('QRScanPage - dispose');
    _isActive = false;
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 이 페이지가 다시 보여질 때 호출됨 (뒤로가기로 돌아왔을 때)
  @override
  void didPopNext() {
    debugPrint('QRScanPage - didPopNext: 뒤로가기로 돌아옴');

    // 페이지를 다시 활성화하고 스캐너 초기화
    setState(() {
      _isActive = true;
    });

    // 잠시 지연 후 권한 체크 및 초기화 진행
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _checkPermissionsAndInitialize();
      }
    });
  }

  // 다른 페이지로 이동할 때 호출됨
  @override
  void didPushNext() {
    debugPrint('QRScanPage - didPushNext: 다른 페이지로 이동');

    // 페이지 비활성화 및 스캐너 중지
    setState(() {
      _isActive = false;
    });

    // 스캐너 확실히 중지
    final scannerService = ref.read(qrScannerServiceProvider);

    // 스캐너가 실행 중이면 강제로 중지
    if (scannerService.isScanning) {
      debugPrint('QRScanPage - didPushNext: 실행 중인 스캐너 중지');
      scannerService.stopScanner().then((_) {
        debugPrint('QRScanPage - didPushNext: 스캐너 중지 완료');
      });
    }

    // 컨트롤러 리셋
    ref.read(qRScanControllerProvider.notifier).resetScanner();
  }

  // 이 페이지가 스택에서 제거될 때 호출됨
  @override
  void didPop() {
    debugPrint('QRScanPage - didPop: 페이지 스택에서 제거됨');
    _isActive = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('QRScanPage - didChangeAppLifecycleState: $state');
    // 앱이 백그라운드에서 포그라운드로 돌아올 때 스캐너 재시작
    if (state == AppLifecycleState.resumed && _isActive) {
      debugPrint('QRScanPage - 앱이 포그라운드로 돌아옴, 스캐너 재시작');
      _checkPermissionsAndInitialize();
    }
  }

  Future<void> _checkPermissionsAndInitialize() async {
    debugPrint('QRScanPage - 권한 체크 및 스캐너 초기화 시작');
    if (!_isActive) {
      debugPrint('QRScanPage - 페이지가 비활성 상태여서 초기화 중단');
      return;
    }

    try {
      // 카메라 권한 체크 - 직접 Permission 객체 사용
      debugPrint('QRScanPage - 카메라 권한 확인 시작');
      var cameraStatus = await Permission.camera.status;
      debugPrint(
        'QRScanPage - 카메라 권한 초기 상태: $cameraStatus (isGranted: ${cameraStatus.isGranted})',
      );

      // 권한이 없으면 요청
      if (!cameraStatus.isGranted) {
        debugPrint('QRScanPage - 카메라 권한 요청 시작');
        cameraStatus = await Permission.camera.request();
        debugPrint(
          'QRScanPage - 카메라 권한 요청 결과: $cameraStatus (isGranted: ${cameraStatus.isGranted})',
        );
      }

      // 위치 권한 체크 - 직접 Permission 객체 사용
      debugPrint('QRScanPage - 위치 권한 확인 시작');
      var locationStatus = await Permission.location.status;
      debugPrint(
        'QRScanPage - 위치 권한 상태: $locationStatus (isGranted: ${locationStatus.isGranted})',
      );

      // 필요한 경우 위치 권한 요청
      if (!locationStatus.isGranted) {
        debugPrint('QRScanPage - 위치 권한 요청 시작');
        locationStatus = await Permission.location.request();
        debugPrint(
          'QRScanPage - 위치 권한 요청 결과: $locationStatus (isGranted: ${locationStatus.isGranted})',
        );
      }

      // 반드시 다시 상태 확인 (최신 상태 반영)
      final hasCamera = await Permission.camera.status.isGranted;
      final hasLocation = await Permission.location.status.isGranted;

      debugPrint('QRScanPage - 최종 카메라 권한: $hasCamera');
      debugPrint('QRScanPage - 최종 위치 권한: $hasLocation');

      // 카메라 권한이 있는 경우에만 초기화
      if (hasCamera) {
        debugPrint('QRScanPage - 권한 확인 완료, 스캐너 컨트롤러 초기화 시작');

        // 스캐너 상태 리셋 먼저 수행 (충돌 방지)
        ref.read(qRScanControllerProvider.notifier).resetScanner();
        await Future.delayed(const Duration(milliseconds: 300));

        // 0.5초 지연 후 초기화 - 더 안정적인 초기화를 위해
        await Future.delayed(const Duration(milliseconds: 500));
        if (_isActive) {
          // 다시 활성 상태 확인
          await ref.read(qRScanControllerProvider.notifier).initialize();
          debugPrint('QRScanPage - 스캐너 컨트롤러 초기화 완료');

          // 상태 명시적으로 다시 활성화 (확실히 활성 상태로 만들기)
          if (mounted) {
            setState(() {
              _isActive = true;
            });
            debugPrint('QRScanPage - 스캐너 초기화 완료 후 _isActive=true로 설정');
          }
        } else {
          debugPrint('QRScanPage - 스캐너 초기화 도중 페이지가 비활성화됨');
        }
      } else {
        debugPrint('QRScanPage - 카메라 권한 없음, 스캐너 초기화 불가');
        // 여기에 사용자에게 권한이 필요하다는 알림 표시 가능
      }
    } catch (e) {
      debugPrint('QRScanPage - 권한 체크 및 초기화 중 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadBannerCount = ref.watch(unreadBannerCountProvider);

    // QR 스캔 결과 스트림 구독 (라우팅용)
    ref.listen(scanResultForRoutingProvider, (previous, next) {
      // QR 스캔 결과 스트림에서 결과가 도착한 경우에만 실행
      if (next.hasValue && _isActive) {
        final result = next.value!;
        debugPrint('QRScanPage - 라우팅 스트림에서 QR 결과 수신: ${result.qrData}');

        // 중복 처리 방지
        setState(() {
          _isActive = false;
        });

        // 스캐너 중지 확인
        final scannerService = ref.read(qrScannerServiceProvider);
        if (scannerService.isScanning) {
          debugPrint('QRScanPage - 스캐너가 아직 실행 중임, 명시적 중지 시도');
          scannerService.stopScanner();
        }

        // 컨트롤러 리셋
        ref.read(qRScanControllerProvider.notifier).resetScanner();

        _performNavigation(context, result.qrData);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR 코드 스캔'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () => _showBannerModal(context),
              ),

              // 읽지 않은 배너 수 표시기
              unreadBannerCount.when(
                data: (count) {
                  if (count > 0) {
                    return Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          count > 9 ? '9+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildScannerView()),
            const SizedBox(height: 20),
            _buildScanInstructions(),
            const SizedBox(height: 20),
            _buildDirectFormButton(context),
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
                  child:
                      _isActive
                          ? MobileScanner(
                            controller: MobileScannerController(
                              detectionSpeed: DetectionSpeed.normal,
                              facing: CameraFacing.back,
                              // 토치는 기본적으로 꺼두기
                              torchEnabled: false,
                            ),
                            onDetect: (capture) {
                              // MobileScanner에서 QR 코드 감지 시 적극적으로 처리
                              if (!_isActive) {
                                debugPrint('QRScanPage - 비활성 상태에서 스캔, 무시');
                                return;
                              }

                              final barcodes = capture.barcodes;
                              if (barcodes.isNotEmpty &&
                                  barcodes.first.rawValue != null) {
                                final qrData = barcodes.first.rawValue!;
                                debugPrint(
                                  'QRScanPage - onDetect: QR 코드 감지됨: $qrData',
                                );

                                // 중복 처리 방지를 위해 즉시 비활성화
                                setState(() {
                                  _isActive = false;
                                });

                                // 스캐너 즉시 중지
                                final scannerService = ref.read(
                                  qrScannerServiceProvider,
                                );
                                scannerService.stopScanner();

                                // QR 값을 ScanResult로 변환하여 직접 스트림에 전달
                                final result = ScanResult(
                                  qrData: qrData,
                                  scanTime: DateTime.now(),
                                );
                                ref
                                    .read(qRScanControllerProvider.notifier)
                                    .handleRawScanResult(result);
                              }
                            },
                          )
                          : Container(
                            color: Colors.black,
                            child: const Center(
                              child: Text(
                                '카메라 초기화 중...',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
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

  // 배너 모달 표시
  void _showBannerModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder:
          (context) => Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: const BannerCarousel(
                height: 520,
                showIndicator: true,
                autoPlay: true,
              ),
            ),
          ),
    );
  }

  // 화면 이동을 위한 별도 메서드 (코드 중복 방지)
  void _performNavigation(BuildContext context, String qrData) {
    // 지연 후 페이지 이동 시도 - 지연 시간 증가 (안정화)
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) {
        debugPrint('QRScanPage - 페이지 이동 불가: mounted=false');
        return;
      }

      debugPrint('QRScanPage - 페이지 이동 시도, qrData: $qrData');

      // 데이터폼 페이지로 직접 이동 (import 추가 필요)
      try {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DataFormPage(qrData: qrData)),
        );
        debugPrint('QRScanPage - MaterialPageRoute 직접 이동 성공');
        return; // 성공했으면 종료
      } catch (e) {
        debugPrint('QRScanPage - MaterialPageRoute 직접 이동 실패: $e');
      }

      // Navigator.pushNamed 시도
      try {
        Navigator.of(context).pushNamed('/form', arguments: qrData);
        debugPrint('QRScanPage - Navigator.pushNamed 성공!');
        return; // 성공했으면 종료
      } catch (e) {
        debugPrint('QRScanPage - Navigator.pushNamed 실패: $e');
      }

      // Go Router 시도
      try {
        context.push('/form', extra: qrData);
        debugPrint('QRScanPage - Go Router로 이동 성공!');
      } catch (e) {
        debugPrint('QRScanPage - 모든 라우팅 방법 실패: $e');
      }
    });
  }

  // 폼 화면으로 직접 이동하는 버튼
  Widget _buildDirectFormButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ElevatedButton.icon(
        onPressed: () {
          // QR 없이 직접 폼 화면으로 이동
          debugPrint('QRScanPage - 직접 입력 버튼 클릭: 페이지 이동 시도');
          _performNavigation(context, 'direct_input:');
        },
        icon: const Icon(Icons.edit_note),
        label: const Text('QR 없이 직접 입력하기'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.blue,
          elevation: 1,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.blue, width: 1),
          ),
        ),
      ),
    );
  }

  // 배너가 있는지 확인하고 표시
  void _checkAndShowBanner() {
    debugPrint('배너 표시 확인 시작...');
    final bannersAsync = ref.read(displayableBannersProvider);

    // 배너 데이터가 있고, 표시할 배너가 있으면 표시
    bannersAsync.when(
      data: (banners) {
        debugPrint('배너 데이터 로드 완료: ${banners.length}개');
        if (banners.isNotEmpty) {
          debugPrint('표시할 배너가 있습니다: ${banners.length}개');
          for (int i = 0; i < banners.length; i++) {
            debugPrint('배너[$i] - ${banners[i].title}');
          }

          if (!_bannerShown) {
            debugPrint('배너 모달 표시 시작');
            _bannerShown = true;
            _showBannerModal(context);
          } else {
            debugPrint('배너가 이미 표시되었습니다.');
          }
        } else {
          debugPrint('표시할 배너가 없습니다.');
        }
      },
      loading: () => debugPrint('배너 데이터 로딩 중...'),
      error: (error, stack) => debugPrint('배너 데이터 로드 오류: $error'),
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
