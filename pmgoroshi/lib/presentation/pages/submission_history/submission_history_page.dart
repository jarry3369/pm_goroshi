import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:pmgoroshi/presentation/controllers/report_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';

class SubmissionHistoryPage extends ConsumerStatefulWidget {
  const SubmissionHistoryPage({Key? key}) : super(key: key);

  @override
  ConsumerState<SubmissionHistoryPage> createState() =>
      _SubmissionHistoryPageState();
}

class _SubmissionHistoryPageState extends ConsumerState<SubmissionHistoryPage> {
  // 네이버 맵 컨트롤러
  NaverMapController? _mapController;

  // 리포트 마커들
  final Map<String, NMarker> _markers = {};

  // 이전 선택된 ID 저장
  String? _previousSelectedId;

  // 이미지 BoxFit 상태 관리
  bool _useContainFit = false;

  // 위치 이동 취소를 위한 변수
  bool _isMovingToCurrentLocation = false;

  @override
  void initState() {
    super.initState();
    // 페이지 로드 시 신고 내역 새로고침
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportDataNotifierProvider.notifier).refreshReports();
    });
  }

  // 현재 위치로 이동
  Future<void> _moveToCurrentLocation() async {
    // 이미 실행 중이면 중복 실행 방지
    if (_isMovingToCurrentLocation) return;

    setState(() {
      _isMovingToCurrentLocation = true;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 2),
      );

      // 중간에 취소되었으면 종료
      if (!_isMovingToCurrentLocation) return;

      // 지도 이동
      _mapController?.updateCamera(
        NCameraUpdate.withParams(
          target: NLatLng(position.latitude, position.longitude),
          zoom: 16,
        ),
      );
    } catch (e) {
      // 중간에 취소되었으면 종료
      if (!_isMovingToCurrentLocation) return;

      // 타임아웃 또는 오류 발생 시 마지막 알려진 위치로 대체
      try {
        Position lastPosition =
            await Geolocator.getLastKnownPosition() ??
            await Geolocator.getPositionStream(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.low,
              ),
            ).first.timeout(const Duration(seconds: 1));

        // 중간에 취소되었으면 종료
        if (!_isMovingToCurrentLocation) return;

        _mapController?.updateCamera(
          NCameraUpdate.withParams(
            target: NLatLng(lastPosition.latitude, lastPosition.longitude),
            zoom: 16,
          ),
        );
      } catch (_) {
        // 중간에 취소되었으면 메시지 표시하지 않음
        if (!_isMovingToCurrentLocation) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('위치를 찾을 수 없습니다'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      // 상태 초기화
      if (mounted) {
        setState(() {
          _isMovingToCurrentLocation = false;
        });
      }
    }
  }

  // 위치 이동 취소
  void _cancelCurrentLocationMovement() {
    if (_isMovingToCurrentLocation) {
      setState(() {
        _isMovingToCurrentLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 신고 데이터 가져오기
    final reportsAsync = ref.watch(reportDataNotifierProvider);
    // 현재 선택된 신고 ID
    final selectedReportId = ref.watch(selectedReportProviderProvider);

    // 선택된 ID가 변경되면 카메라 이동
    if (selectedReportId != null &&
        selectedReportId != _previousSelectedId &&
        reportsAsync.hasValue) {
      _moveCameraToReport(selectedReportId, reportsAsync.value!);
      _previousSelectedId = selectedReportId;
    } else if (selectedReportId == null) {
      _previousSelectedId = null;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('신고 지도'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // 새로고침
              ref.read(reportDataNotifierProvider.notifier).refreshReports();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 네이버 지도 위젯
          NaverMap(
            options: const NaverMapViewOptions(
              initialCameraPosition: NCameraPosition(
                target: NLatLng(37.5666102, 126.9783881), // 서울 시청
                zoom: 12,
              ),
              rotationGesturesEnable: false,
              extent: NLatLngBounds(
                southWest: NLatLng(33.0, 124.5), // 대한민국 최남서단 (마라도 근처)
                northEast: NLatLng(38.6, 131.0), // 대한민국 최북동단 (독도 포함)
              ),
              minZoom: 6, // 대한민국 전체가 보이는 최소 줌 레벨
              maxZoom: 19, // 상세 건물이 보이는 최대 줌 레벨
              indoorEnable: false,
            ),
            onMapReady: (controller) {
              _mapController = controller;

              // 신고 데이터가 이미 로드되었다면 마커 추가
              if (reportsAsync.hasValue) {
                _addMarkersToMap(reportsAsync.value ?? [], initialLoad: true);
              }
            },
            onMapTapped: (point, latLng) {
              // 지도 탭하면 선택 해제
              ref
                  .read(selectedReportProviderProvider.notifier)
                  .clearSelection();

              // 위치 이동 중단
              _cancelCurrentLocationMovement();
            },
            onCameraChange: (reason, animated) {
              // 드래그로 카메라가 움직이면 위치 이동 중단
              if (reason == NCameraUpdateReason.gesture ||
                  reason == NCameraUpdateReason.control) {
                _cancelCurrentLocationMovement();
              }
            },
          ),

          // 신고 데이터 로딩 상태 처리
          reportsAsync.when(
            data: (reports) {
              // 데이터가 로드되고 컨트롤러가 준비되면 마커 추가
              if (_mapController != null) {
                _addMarkersToMap(reports, initialLoad: false);
              }
              return const SizedBox.shrink();
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (error, stack) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text('데이터 로드 중 오류 발생: $error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // 다시 시도
                          ref
                              .read(reportDataNotifierProvider.notifier)
                              .refreshReports();
                        },
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                ),
          ),

          // 범례 표시
          Positioned(
            top: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('미처리된 신고'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('처리된 신고'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 현재 위치 버튼
          if (selectedReportId == null)
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton(
                heroTag: 'currentLocationButton',
                onPressed: _moveToCurrentLocation,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.my_location,
                  color: Colors.lightBlue.shade400,
                ),
              ),
            ),

          // 선택된 신고 상세 정보 표시
          if (selectedReportId != null &&
              reportsAsync.hasValue &&
              reportsAsync.value!.isNotEmpty)
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: -40,
                    right: 20,
                    child: GestureDetector(
                      onTap: () {
                        ref
                            .read(selectedReportProviderProvider.notifier)
                            .clearSelection();
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.close, color: Colors.grey),
                      ),
                    ),
                  ),

                  _buildReportDetailCard(
                    reportsAsync.value!.firstWhere(
                      (report) => report.id == selectedReportId,
                      orElse: () => reportsAsync.value!.first,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // 선택된 리포트로 카메라 이동 함수
  void _moveCameraToReport(String reportId, List<ReportData> reports) {
    if (_mapController == null) return;

    final report = reports.firstWhere(
      (report) => report.id == reportId,
      orElse: () => reports.first,
    );

    _mapController?.updateCamera(
      NCameraUpdate.withParams(
        target: NLatLng(report.latitude - 0.0001, report.longitude),
        zoomBy: 16,
      ),
    );
  }

  // 마커를 지도에 추가하는 함수
  void _addMarkersToMap(List<ReportData> reports, {bool initialLoad = false}) {
    // 이전 마커 관련 변수 정리
    _markers.clear();

    if (_mapController == null) return;

    // 새 마커 추가
    for (final report in reports) {
      // 기본 마커 생성
      final marker = NMarker(
        id: report.id,
        position: NLatLng(report.latitude, report.longitude),
      );

      // 마커 클릭 이벤트 설정
      marker.setOnTapListener((overlay) {
        // 신고 선택 (카메라 이동은 위젯 빌드 이후에 처리)
        ref
            .read(selectedReportProviderProvider.notifier)
            .selectReport(report.id);
      });

      // 지도에 마커 추가
      _mapController!.addOverlay(marker);
      _markers[report.id] = marker;
    }

    // 카메라 이동 (선택된 마커가 없고 초기 로드일 때만)
    String? selectedId = ref.read(selectedReportProviderProvider);
    if (reports.isNotEmpty && selectedId == null && initialLoad) {
      final positions =
          reports
              .map((report) => NLatLng(report.latitude, report.longitude))
              .toList();

      _mapController?.updateCamera(
        NCameraUpdate.fitBounds(
          NLatLngBounds.from(positions),
          padding: const EdgeInsets.all(50),
        ),
      );
    }
  }

  // 신고 상세 정보 카드
  Widget _buildReportDetailCard(ReportData report) {
    final dateFormat = DateFormat('yyyy년 MM월 dd일 HH:mm');

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 제목 및 상태
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.id,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        dateFormat.format(report.reportedAt),
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: report.processed ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        report.processed ? Icons.check_circle : Icons.warning,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        report.processed ? '처리완료' : '미처리',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 이미지 캐러셀
          SizedBox(
            height: 200,
            child:
                report.imageUrls.isEmpty
                    ? const Center(child: Text('이미지가 없습니다'))
                    : PageView.builder(
                      itemCount: report.imageUrls.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            // 이미지
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _useContainFit = !_useContainFit;
                                });
                              },
                              child: CachedNetworkImage(
                                imageUrl: report.imageUrls[index],
                                placeholder:
                                    (context, url) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                errorWidget:
                                    (context, url, error) => const Center(
                                      child: Icon(
                                        Icons.error_outline,
                                        size: 50,
                                        color: Colors.red,
                                      ),
                                    ),
                                fit:
                                    _useContainFit
                                        ? BoxFit.contain
                                        : BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),

                            // 이미지 개수 표시기
                            if (report.imageUrls.length > 1)
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${index + 1}/${report.imageUrls.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                            // BoxFit 모드 표시
                            Positioned(
                              bottom: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _useContainFit ? '원본 비율' : '화면 맞춤',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 신고 내용
                if (report.description != null &&
                    report.description!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '신고 내용',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(report.description!),
                    ],
                  ),

                // 주소
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 2, 0, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              report.address,
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
