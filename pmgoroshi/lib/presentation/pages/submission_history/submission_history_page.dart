import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:pmgoroshi/presentation/controllers/report_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

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

  // 선택된 마커의 정보 창
  NInfoWindow? _infoWindow;

  // 이전 선택된 ID 저장
  String? _previousSelectedId;

  @override
  void initState() {
    super.initState();
    // 페이지 로드 시 신고 내역 새로고침
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportDataNotifierProvider.notifier).refreshReports();
    });
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

          // 선택된 신고 상세 정보 표시
          if (selectedReportId != null &&
              reportsAsync.hasValue &&
              reportsAsync.value!.isNotEmpty)
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: _buildReportDetailCard(
                reportsAsync.value!.firstWhere(
                  (report) => report.id == selectedReportId,
                  orElse: () => reportsAsync.value!.first,
                ),
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

    // 카메라 이동
    _mapController?.updateCamera(
      NCameraUpdate.withParams(
        target: NLatLng(report.latitude - 0.0003, report.longitude),
        zoom: 18,
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
          // 제목 및 닫기 버튼
          ListTile(
            title: Text(
              report.id,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${dateFormat.format(report.reportedAt)}\n${report.address}',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                ref
                    .read(selectedReportProviderProvider.notifier)
                    .clearSelection();
              },
            ),
            isThreeLine: true,
          ),

          // 이미지
          ClipRRect(
            child: CachedNetworkImage(
              imageUrl: report.imageUrl,
              placeholder:
                  (context, url) => const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  ),
              errorWidget:
                  (context, url, error) => const SizedBox(
                    height: 200,
                    child: Center(
                      child: Icon(
                        Icons.error_outline,
                        size: 50,
                        color: Colors.red,
                      ),
                    ),
                  ),
              fit: BoxFit.cover,
              height: 200,
              width: double.infinity,
            ),
          ),

          if (report.description != null && report.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(report.description!),
            ),
        ],
      ),
    );
  }
}
