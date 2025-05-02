import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:pmgoroshi/presentation/controllers/report_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

// 임시로 Provider를 직접 정의 (코드 생성기 실행 전까지)
final reportDataProvider = FutureProvider<List<ReportData>>((ref) async {
  // 예시 데이터 반환
  return [
    ReportData(
      id: '1',
      title: '불법 주차된 킥보드',
      imageUrl: 'https://via.placeholder.com/400x300?text=Kickboard+1',
      latitude: 37.566,
      longitude: 126.978,
      reportedAt: DateTime.now(),
      address: '서울시 중구 세종대로',
      description: '인도에 주차되어 보행자의 통행을 방해하고 있습니다.',
    ),
    ReportData(
      id: '2',
      title: '쓰러진 킥보드',
      imageUrl: 'https://via.placeholder.com/400x300?text=Kickboard+2',
      latitude: 37.557,
      longitude: 126.970,
      reportedAt: DateTime.now().subtract(const Duration(days: 1)),
      address: '서울시 용산구 이태원로',
      description: '도로 중앙에 쓰러져 있습니다.',
    ),
    ReportData(
      id: '3',
      title: '파손된 킥보드',
      imageUrl: 'https://via.placeholder.com/400x300?text=Kickboard+3',
      latitude: 37.575,
      longitude: 126.973,
      reportedAt: DateTime.now().subtract(const Duration(days: 2)),
      address: '서울시 종로구 삼청동',
      description: '배터리가 분리되어 있고 핸들이 파손되었습니다.',
    ),
  ];
});

final selectedReportIdProvider = StateProvider<String?>((ref) => null);

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

  @override
  void initState() {
    super.initState();
    // 페이지 로드 시 신고 내역 새로고침 (실제 구현될 때까지 주석처리)
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   ref.read(reportDataNotifierProvider.notifier).refreshReports();
    // });
  }

  @override
  Widget build(BuildContext context) {
    // 신고 데이터 가져오기 (임시 Provider 사용)
    final reportsAsync = ref.watch(reportDataProvider);
    // 현재 선택된 신고 ID
    final selectedReportId = ref.watch(selectedReportIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('신고 지도'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // 새로고침
              ref.refresh(reportDataProvider);
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
            ),
            onMapReady: (controller) {
              _mapController = controller;

              // 신고 데이터가 이미 로드되었다면 마커 추가
              if (reportsAsync.hasValue) {
                _addMarkersToMap(reportsAsync.value ?? []);
              }
            },
            onMapTapped: (point, latLng) {
              // 지도 탭하면 선택 해제
              ref.read(selectedReportIdProvider.notifier).state = null;
            },
          ),

          // 신고 데이터 로딩 상태 처리
          reportsAsync.when(
            data: (reports) {
              // 데이터가 로드되고 컨트롤러가 준비되면 마커 추가
              if (_mapController != null) {
                _addMarkersToMap(reports);
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
                          ref.refresh(reportDataProvider);
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

  // 마커를 지도에 추가하는 함수
  void _addMarkersToMap(List<ReportData> reports) {
    // 기존 마커 모두 제거
    for (final marker in _markers.values) {
      _mapController?.addOverlay(marker);
    }
    _markers.clear();

    // 새 마커 추가
    for (final report in reports) {
      // 기본 마커 생성
      final marker = NMarker(
        id: report.id,
        position: NLatLng(report.latitude, report.longitude),
      );

      // 마커 클릭 이벤트 설정
      marker.setOnTapListener((overlay) {
        // 신고 선택
        ref.read(selectedReportIdProvider.notifier).state = report.id;

        // 카메라 이동
        _mapController?.updateCamera(
          NCameraUpdate.withParams(
            target: NLatLng(report.latitude, report.longitude),
            zoom: 16,
          ),
        );
      });

      // 지도에 마커 추가
      _mapController?.addOverlay(marker);
      _markers[report.id] = marker;
    }

    // 마커가 있으면 모든 마커가 보이도록 카메라 위치 조정
    if (reports.isNotEmpty) {
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
        mainAxisSize: MainAxisSize.min,
        children: [
          // 제목 및 닫기 버튼
          ListTile(
            title: Text(
              report.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${dateFormat.format(report.reportedAt)}\n${report.address}',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                ref.read(selectedReportIdProvider.notifier).state = null;
              },
            ),
            isThreeLine: true,
          ),

          // 이미지
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
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

          // 설명이 있는 경우 표시
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
