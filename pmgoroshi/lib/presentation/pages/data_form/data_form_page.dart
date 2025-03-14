import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pmgoroshi/presentation/pages/data_form/data_form_controller.dart';
import 'package:pmgoroshi/domain/entities/form_data.dart';
import 'package:pmgoroshi/domain/entities/violation_type.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

// DataFormPage를 다시 ConsumerWidget으로 변경
class DataFormPage extends ConsumerWidget {
  const DataFormPage({super.key, required this.qrData});

  final String qrData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('데이터 입력'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQrDataCard(context, qrData, ref),
              const SizedBox(height: 24),
              LocationSection(qrData: qrData),
              const SizedBox(height: 24),
              ViolationTypeSection(qrData: qrData),
              const SizedBox(height: 24),
              DescriptionSection(qrData: qrData),
              const SizedBox(height: 24),
              ImagePickerSection(qrData: qrData),
              const SizedBox(height: 32),
              ErrorMessageSection(qrData: qrData),
              const SizedBox(height: 16),
              SubmitButtonSection(qrData: qrData),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQrDataCard(BuildContext context, String qrData, WidgetRef ref) {
    return FutureBuilder<(String, String?)>(
      future: ref
          .read(dataFormControllerProvider(qrData).notifier)
          .parseQrData(qrData),
      builder: (context, snapshot) {
        String companyName = "로딩 중...";
        String? serialNumber;

        if (snapshot.hasData) {
          (companyName, serialNumber) = snapshot.data!;
        } else if (snapshot.hasError) {
          companyName = "오류 발생";
          serialNumber = null;
        }

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'QR 코드 정보',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  qrData,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                // 업체 정보 표시
                Row(
                  children: [
                    Text(
                      '업체명: ',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        companyName,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 시리얼 넘버 표시
                Row(
                  children: [
                    Text(
                      '시리얼 번호: ',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        serialNumber ?? '알 수 없음',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// 위치 정보 섹션을 별도의 위젯으로 분리
class LocationSection extends ConsumerStatefulWidget {
  const LocationSection({super.key, required this.qrData});

  final String qrData;

  @override
  ConsumerState<LocationSection> createState() => _LocationSectionState();
}

class _LocationSectionState extends ConsumerState<LocationSection> {
  // 위치 정보 위젯 참조 저장 (캐싱 용도)
  MapWidgetWithCache? _cachedMapWidget;
  bool _hasInitialized = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dataFormControllerProvider(widget.qrData));
    final controller = ref.read(
      dataFormControllerProvider(widget.qrData).notifier,
    );

    // 위치 정보가 있을 때만 맵 위젯 초기화 (최초 1회)
    if (state.position != null && !_hasInitialized) {
      _cachedMapWidget = MapWidgetWithCache(
        key: ValueKey(
          'map_${state.position!.latitude}_${state.position!.longitude}',
        ),
        latitude: state.position!.latitude,
        longitude: state.position!.longitude,
      );
      _hasInitialized = true;
    }

    // 위치 변경 시에만 맵 위젯 업데이트
    if (state.position != null && _hasInitialized && _cachedMapWidget != null) {
      final latKey = _cachedMapWidget!.key as ValueKey;
      final keyString = latKey.value.toString();
      final newKeyString =
          'map_${state.position!.latitude}_${state.position!.longitude}';

      if (keyString != newKeyString) {
        _cachedMapWidget = MapWidgetWithCache(
          key: ValueKey(newKeyString),
          latitude: state.position!.latitude,
          longitude: state.position!.longitude,
        );
      }
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '현재 위치',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // 로딩 상태에 따른 새로고침 버튼
                _RefreshLocationButton(
                  isLoading: state.isLocationLoading,
                  onRefresh: controller.refreshLocation,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 로딩 표시 영역
            if (state.isLocationLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              ),

            // 위치 정보 및 맵 표시 영역
            if (!state.isLocationLoading && state.position != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 도로명 주소 표시
                  if (state.location != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Text(
                        state.location!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),

                  // 캐시된 맵 위젯 표시
                  if (_cachedMapWidget != null) _cachedMapWidget!,
                ],
              )
            else if (!state.isLocationLoading)
              OutlinedButton.icon(
                onPressed: controller.refreshLocation,
                icon: const Icon(Icons.location_on),
                label: const Text('위치 정보 가져오기'),
              ),
          ],
        ),
      ),
    );
  }
}

// 위치 새로고침 버튼 위젯 분리
class _RefreshLocationButton extends StatelessWidget {
  const _RefreshLocationButton({
    Key? key,
    required this.isLoading,
    required this.onRefresh,
  }) : super(key: key);

  final bool isLoading;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.refresh),
      onPressed: isLoading ? null : onRefresh,
      tooltip: '위치 새로고침',
    );
  }
}

// 위반 유형 선택 섹션 분리
class ViolationTypeSection extends ConsumerWidget {
  const ViolationTypeSection({super.key, required this.qrData});

  final String qrData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      dataFormControllerProvider(qrData).select((s) => s.violationType),
    );
    final controller = ref.read(dataFormControllerProvider(qrData).notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '위반 유형',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButtonFormField<ViolationType>(
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
              hint: const Text('위반 유형을 선택하세요'),
              value: state,
              isExpanded: true,
              items:
                  violationTypes.asMap().entries.map((e) {
                    return DropdownMenuItem<ViolationType>(
                      value: e.value,
                      child: Text(
                        '${e.key + 1}. ${e.value.name}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  controller.updateViolationType(value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

// 설명 입력 섹션 분리
class DescriptionSection extends ConsumerWidget {
  const DescriptionSection({super.key, required this.qrData});

  final String qrData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final description = ref.watch(
      dataFormControllerProvider(qrData).select((s) => s.description),
    );
    final controller = ref.read(dataFormControllerProvider(qrData).notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '상세 설명',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: description,
          onChanged: controller.updateDescription,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: '상세 내용을 입력하세요',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }
}

// 이미지 첨부 섹션 분리
class ImagePickerSection extends ConsumerWidget {
  const ImagePickerSection({super.key, required this.qrData});

  final String qrData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imagePaths = ref.watch(
      dataFormControllerProvider(qrData).select((s) => s.imagePaths),
    );
    final controller = ref.read(dataFormControllerProvider(qrData).notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '사진 첨부',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: controller.pickImageFromGallery,
              icon: const Icon(Icons.photo_library),
              label: const Text('갤러리'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: controller.pickImageFromCamera,
              icon: const Icon(Icons.camera_alt),
              label: const Text('카메라'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (imagePaths.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: imagePaths.length,
            itemBuilder: (context, index) {
              final imagePath = imagePaths[index];
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(imagePath),
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => controller.removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }
}

// 에러 메시지 섹션 분리
class ErrorMessageSection extends ConsumerWidget {
  const ErrorMessageSection({super.key, required this.qrData});

  final String qrData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errorMessage = ref.watch(
      dataFormControllerProvider(qrData).select((s) => s.errorMessage),
    );

    if (errorMessage == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorMessage,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }
}

// 제출 버튼 섹션 분리
class SubmitButtonSection extends ConsumerWidget {
  const SubmitButtonSection({super.key, required this.qrData});

  final String qrData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      dataFormControllerProvider(
        qrData,
      ).select((s) => (isSubmitting: s.isSubmitting, isSuccess: s.isSuccess)),
    );
    final controller = ref.read(dataFormControllerProvider(qrData).notifier);

    // 성공한 경우만 듣도록 하는 리스너는 더이상 필요 없음
    // 제출 버튼으로 직접 이동 로직을 처리함

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed:
            state.isSubmitting
                ? null
                : () async {
                  // 제출 함수 직접 호출 후 결과에 따라 처리
                  final result = await controller.submitForm();

                  if (context.mounted) {
                    // 성공/실패 여부와 상관없이 Completion 페이지로 이동
                    context.go(
                      '/completion',
                      extra: {
                        'isSuccess': result.isSuccess,
                        'errorMessage': result.errorMessage,
                        'submissionTime':
                            result.data?.submissionTime.toIso8601String() ??
                            DateTime.now().toIso8601String(),
                      },
                    );
                  }
                },
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child:
            state.isSubmitting
                ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
                : const Text(
                  '제출하기',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
      ),
    );
  }
}

// 맵 위젯 싱글톤 관리를 위한 글로벌 키 추가
final _naverMapKey = GlobalKey();

// 캐싱 메커니즘이 적용된 맵 위젯
class MapWidgetWithCache extends StatefulWidget {
  const MapWidgetWithCache({
    Key? key,
    required this.latitude,
    required this.longitude,
  }) : super(key: key);

  final double latitude;
  final double longitude;

  @override
  State<MapWidgetWithCache> createState() => _MapWidgetWithCacheState();
}

class _MapWidgetWithCacheState extends State<MapWidgetWithCache>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return OptimizedNaverMapWidget(
      key: _naverMapKey, // 글로벌 키 사용
      latitude: widget.latitude,
      longitude: widget.longitude,
    );
  }
}

// 최적화된 NaverMap 위젯
class OptimizedNaverMapWidget extends StatefulWidget {
  const OptimizedNaverMapWidget({
    Key? key,
    required this.latitude,
    required this.longitude,
  }) : super(key: key);

  final double latitude;
  final double longitude;

  @override
  State<OptimizedNaverMapWidget> createState() =>
      _OptimizedNaverMapWidgetState();
}

class _OptimizedNaverMapWidgetState extends State<OptimizedNaverMapWidget> {
  static NaverMapController? _mapController;
  static NMarker? _marker;
  static bool _isMapInitialized = false;

  // ValueNotifier를 통한 위치 변경 감지
  late final ValueNotifier<NLatLng> _positionNotifier;

  @override
  void initState() {
    super.initState();
    _positionNotifier = ValueNotifier<NLatLng>(
      NLatLng(widget.latitude, widget.longitude),
    );
  }

  @override
  void dispose() {
    // 앱이 종료될 때만 위젯이 dispose 되도록 처리
    // 일반적인 리빌드에서는 _mapController 유지
    _positionNotifier.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(OptimizedNaverMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 위치가 변경된 경우에만 업데이트 진행
    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude) {
      _positionNotifier.value = NLatLng(widget.latitude, widget.longitude);
      _updateMapAndMarker();
    }
  }

  void _updateMapAndMarker() {
    // 맵이 초기화되지 않았으면 아무 작업도 하지 않음
    if (!_isMapInitialized || _mapController == null) return;

    // 카메라 이동 (애니메이션 없이 즉시 이동)
    _mapController!.updateCamera(
      NCameraUpdate.withParams(
        target: NLatLng(widget.latitude, widget.longitude),
      ),
    );

    // 마커가 이미 있으면 위치만 업데이트
    if (_marker != null) {
      _marker!.setPosition(NLatLng(widget.latitude, widget.longitude));
    }
  }

  @override
  Widget build(BuildContext context) {
    // 맵이 이미 초기화되었고 위치만 변경된 경우 빈 컨테이너를 사용하여 리렌더링 방지
    if (_isMapInitialized && _mapController != null) {
      _updateMapAndMarker();

      // 지도 크기와 모양만 유지하는 컨테이너 반환 (내부 맵은 업데이트만 함)
      // 이미 초기화된 맵을 보여주기 위해 ClipRRect로 감싸서 보이게 함
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        clipBehavior: Clip.antiAlias, // 지도가 경계를 넘어가지 않도록
        child: const SizedBox.expand(), // 지도가 보이도록 확장
      );
    }

    // 최초 렌더링 시에만 실제 맵 위젯 생성
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: RepaintBoundary(
          child: NaverMap(
            options: NaverMapViewOptions(
              initialCameraPosition: NCameraPosition(
                target: NLatLng(widget.latitude, widget.longitude),
                zoom: 17,
              ),
              mapType: NMapType.basic,
              maxZoom: 20,
              minZoom: 15,
              logoClickEnable: false,
              nightModeEnable: true,
              zoomGesturesEnable: true,
              locationButtonEnable: false,
            ),
            onMapReady: (controller) {
              // 컨트롤러를 static 변수에 저장하여 재사용
              _mapController = controller;
              _isMapInitialized = true;
              _addMarker();
            },
          ),
        ),
      ),
    );
  }

  void _addMarker() {
    if (_mapController == null) return;

    // 마커가 없는 경우에만 추가
    if (_marker == null) {
      _marker = NMarker(
        id: 'current-location',
        position: NLatLng(widget.latitude, widget.longitude),
      );
      _mapController!.addOverlay(_marker!);
    } else {
      // 마커가 이미 있으면 위치만 업데이트
      _marker!.setPosition(NLatLng(widget.latitude, widget.longitude));
    }
  }
}
