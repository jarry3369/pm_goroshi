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
    // 제출 상태 관찰
    final isSubmitting = ref.watch(
      dataFormControllerProvider(qrData).select((s) => s.isSubmitting),
    );

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(title: const Text('데이터 입력'), elevation: 0),
          body: GestureDetector(
            // 화면의 빈 공간을 터치하면 키보드를 숨김
            onTap: () => FocusScope.of(context).unfocus(),
            // 제스처 이벤트가 자식 위젯에 전달되도록 설정
            behavior: HitTestBehavior.translucent,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
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
                    const SizedBox(height: 24),
                    SubmitButtonSection(qrData: qrData),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),

        // 제출 중일 때 표시되는 전체 화면 오버레이
        if (isSubmitting)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF3B82F6),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '제출 중입니다...',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF3B82F6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '잠시만 기다려주세요',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQrDataCard(BuildContext context, String qrData, WidgetRef ref) {
    // 컨트롤러를 명시적으로 변수에 할당
    final controller = ref.read(dataFormControllerProvider(qrData).notifier);
    
    // qrData 상태를 관찰하여 변경될 때 UI 업데이트 (회사 선택 시)
    final currentQrData = ref.watch(
      dataFormControllerProvider(qrData).select((s) => s.qrData)
    );
    
    // 현재 상태의 qrData를 기반으로 파싱
    final infoFuture = controller.parseQrData(currentQrData);
    
    // 직접 입력 모드 또는 수동 선택 모드 여부 확인
    final isDirectInputMode = currentQrData.startsWith('direct_input:');
    final isManuallySelected = currentQrData.startsWith('manual_selected:');

    return FutureBuilder<(String, String?)>(
      future: infoFuture,
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
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isDirectInputMode || isManuallySelected 
                            ? Icons.business 
                            : Icons.qr_code,
                        color: const Color(0xFF3B82F6),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isDirectInputMode || isManuallySelected 
                          ? '회사 정보' 
                          : 'QR 코드 정보',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // 직접 입력 모드 또는 수동 선택 모드면 항상 회사 선택 UI 표시
                if (isDirectInputMode || isManuallySelected)
                  _buildCompanySelector(context, controller, companyName)
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      currentQrData,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade800,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                // 업체 정보 표시
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(
                          '업체명',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          companyName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // 시리얼 넘버 표시 (직접 입력 모드가 아닐 때만)
                if (!isDirectInputMode && !isManuallySelected)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(
                          '시리얼 번호',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          serialNumber ?? '알 수 없음',
                          style: const TextStyle(fontWeight: FontWeight.bold),
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

  // 회사 선택 위젯
  Widget _buildCompanySelector(BuildContext context, DataFormController controller, String currentCompanyName) {
    // 이미 회사가 선택되었는지 확인
    final bool hasSelectedCompany = currentCompanyName != '회사를 선택해주세요' && 
                                    currentCompanyName != '로딩 중...' &&
                                    currentCompanyName != '오류 발생';
    
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.business, size: 20, color: Colors.grey.shade600),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hasSelectedCompany 
                      ? currentCompanyName 
                      : '회사를 선택하세요',
                  style: TextStyle(
                    color: hasSelectedCompany 
                        ? Colors.black 
                        : Colors.grey.shade700,
                    fontWeight: hasSelectedCompany 
                        ? FontWeight.bold 
                        : FontWeight.normal,
                  ),
                ),
              ),
              SizedBox(
                width: 100, // 명시적인 너비 지정
                child: ElevatedButton(
                  onPressed: () => _showCompanySelectionDialog(context, controller),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(hasSelectedCompany ? '변경하기' : '선택하기'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 회사 선택 다이얼로그
  Future<void> _showCompanySelectionDialog(BuildContext context, DataFormController controller) async {
    // 회사 목록 가져오기
    final companies = await controller.getCompanyList();
    
    if (!context.mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  child: Row(
                    children: [
                      const Text(
                        '회사 선택',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    itemCount: companies.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final companyName = companies[index];
                      return ListTile(
                        title: Text(companyName),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pop(context);
                          // 선택한 회사 정보 업데이트
                          controller.updateSelectedCompany(companyName);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
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
  void dispose() {
    _cachedMapWidget = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dataFormControllerProvider(widget.qrData));
    final controller = ref.read(
      dataFormControllerProvider(widget.qrData).notifier,
    );

    // 위치 정보가 있을 때만 맵 위젯 초기화 (최초 1회 또는 재빌드시)
    if (state.position != null &&
        (!_hasInitialized || _cachedMapWidget == null)) {
      _cachedMapWidget = MapWidgetWithCache(
        key: ValueKey(
          'map_${state.position!.latitude}_${state.position!.longitude}_${DateTime.now().millisecondsSinceEpoch}',
        ),
        latitude: state.position!.latitude,
        longitude: state.position!.longitude,
      );
      _hasInitialized = true;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.location_on,
                color: Color(0xFF3B82F6),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '위치 정보',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            if (state.isLocationLoading)
              Container(
                width: 16,
                height: 16,
                margin: const EdgeInsets.only(right: 8),
                child: CircularProgressIndicator(
                  color: Colors.grey.shade500,
                  strokeWidth: 2,
                ),
              ),
            TextButton.icon(
              onPressed:
                  state.isLocationLoading
                      ? null
                      : () {
                        // 키보드 숨기기
                        FocusScope.of(context).unfocus();
                        // 리빌드를 위한 함수가 없어서 추가
                        void _rebuildMapIfNeeded() {
                          if (state.position != null) {
                            setState(() {
                              _hasInitialized = false;
                              _cachedMapWidget = null;
                            });
                          }
                        }

                        // 위치 갱신 후 지도 리빌드
                        controller.refreshLocation().then((_) {
                          _rebuildMapIfNeeded();
                        });
                      },
              icon: Icon(
                Icons.refresh,
                size: 16,
                color: const Color(
                  0xFF3B82F6,
                ).withOpacity(state.isLocationLoading ? 0.5 : 1.0),
              ),
              label: Text(
                '새로고침',
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(
                    0xFF3B82F6,
                  ).withOpacity(state.isLocationLoading ? 0.5 : 1.0),
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 지도 표시
        Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            color: Colors.grey.shade100,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child:
                state.position == null
                    ? const Center(child: Text('위치 정보 로딩 중...'))
                    : _cachedMapWidget,
          ),
        ),

        const SizedBox(height: 16),
        // 주소 정보 표시
        if (state.location != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.location!,
                    style: TextStyle(color: Colors.grey.shade800, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// 위반 유형 선택 섹션 분리
class ViolationTypeSection extends ConsumerWidget {
  const ViolationTypeSection({super.key, required this.qrData});

  final String qrData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final violationType = ref.watch(
      dataFormControllerProvider(qrData).select((s) => s.violationType),
    );
    final controller = ref.read(dataFormControllerProvider(qrData).notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.error_outline,
                color: Color(0xFF3B82F6),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '위반 유형',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: List.generate(violationTypes.length, (index) {
              final type = violationTypes[index];
              final isSelected = violationType == type;
              final isLast = index == violationTypes.length - 1;

              return InkWell(
                onTap: () => controller.updateViolationType(type),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom:
                          !isLast
                              ? BorderSide(color: Colors.grey.shade100)
                              : BorderSide.none,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                isSelected
                                    ? const Color(0xFF3B82F6)
                                    : Colors.grey.shade400,
                            width: 2,
                          ),
                          color:
                              isSelected
                                  ? const Color(0xFF3B82F6)
                                  : Colors.transparent,
                        ),
                        child:
                            isSelected
                                ? const Icon(
                                  Icons.check,
                                  size: 12,
                                  color: Colors.white,
                                )
                                : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          type.name,
                          style: TextStyle(
                            fontWeight:
                                isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                            color:
                                isSelected
                                    ? const Color(0xFF3B82F6)
                                    : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
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
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.description,
                color: Color(0xFF3B82F6),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '설명',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextField(
            maxLines: 5,
            minLines: 3,
            onChanged: controller.updateDescription,
            decoration: InputDecoration(
              hintText: '위반 내용에 대한 설명을 입력해주세요',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            style: const TextStyle(height: 1.5),
            // 자동 포커스 방지
            autofocus: false,
            // 키보드 유형 설정
            keyboardType: TextInputType.multiline,
            // 입력 완료 시 키보드 숨김 설정
            textInputAction: TextInputAction.done,
            onEditingComplete: () => FocusScope.of(context).unfocus(),
          ),
        ),
        if (description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              '${description.length}/500자',
              style: TextStyle(
                fontSize: 12,
                color:
                    description.length > 500
                        ? Colors.red
                        : Colors.grey.shade600,
              ),
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
  // 최대 이미지 개수 상수 정의
  static const int maxImages = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imagePaths = ref.watch(
      dataFormControllerProvider(qrData).select((s) => s.imagePaths),
    );
    final isImageLoading = ref.watch(
      dataFormControllerProvider(qrData).select((s) => s.isImageLoading),
    );
    final controller = ref.read(dataFormControllerProvider(qrData).notifier);

    // 이미지가 최대 개수에 도달했는지 확인
    final bool isMaxImagesReached = imagePaths.length >= maxImages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.photo,
                color: Color(0xFF3B82F6),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '사진 첨부',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            // 이미지 로딩 인디케이터 추가
            if (isImageLoading)
              Container(
                width: 16,
                height: 16,
                margin: const EdgeInsets.only(right: 8),
                child: CircularProgressIndicator(
                  color: Colors.grey.shade500,
                  strokeWidth: 2,
                ),
              ),
            // 이미지 수 표시 추가
            Text(
              '${imagePaths.length}/$maxImages',
              style: TextStyle(
                color: isMaxImagesReached ? Colors.red : Colors.grey.shade600,
                fontWeight:
                    isMaxImagesReached ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    isMaxImagesReached || isImageLoading
                        ? null // 최대 개수에 도달하거나 로딩 중이면 버튼 비활성화
                        : () async {
                          if (imagePaths.length >= maxImages) {
                            // 이미 최대 개수라면 스낵바 표시
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('최대 $maxImages장까지만 업로드 가능합니다'),
                                backgroundColor: Colors.red.shade700,
                              ),
                            );
                            return;
                          }
                          controller.pickMultipleImagesFromGallery();
                        },
                icon: const Icon(Icons.photo_library),
                label: const Text('갤러리'),
                style: OutlinedButton.styleFrom(
                  disabledForegroundColor: Colors.grey.shade400,
                  disabledBackgroundColor: Colors.grey.shade100,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    isMaxImagesReached || isImageLoading
                        ? null // 최대 개수에 도달하거나 로딩 중이면 버튼 비활성화
                        : () async {
                          if (imagePaths.length >= maxImages) {
                            // 이미 최대 개수라면 스낵바 표시
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('최대 $maxImages장까지만 업로드 가능합니다'),
                                backgroundColor: Colors.red.shade700,
                              ),
                            );
                            return;
                          }
                          controller.pickImageFromCamera();
                        },
                icon: const Icon(Icons.camera_alt),
                label: const Text('카메라'),
                style: OutlinedButton.styleFrom(
                  disabledForegroundColor: Colors.grey.shade400,
                  disabledBackgroundColor: Colors.grey.shade100,
                ),
              ),
            ),
          ],
        ),
        // 최대 이미지 설명 메시지 추가
        if (isMaxImagesReached)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '최대 이미지 개수($maxImages장)에 도달했습니다.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        const SizedBox(height: 16),
        if (imagePaths.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: imagePaths.length,
            itemBuilder: (context, index) {
              final imagePath = imagePaths[index];
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.file(
                        File(imagePath),
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => controller.removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.black54,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            child: Icon(
              Icons.error_outline,
              color: Colors.red.shade700,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              errorMessage,
              style: TextStyle(color: Colors.red.shade700, height: 1.5),
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

    return SizedBox(
      width: double.infinity,
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
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (state.isSubmitting)
                Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(right: 12),
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              Text(
                state.isSubmitting ? '제출 중...' : '제출하기',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
      key: ValueKey('map_${widget.latitude}_${widget.longitude}'),
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

class _OptimizedNaverMapWidgetState extends State<OptimizedNaverMapWidget>
    with WidgetsBindingObserver {
  NaverMapController? _mapController;
  NMarker? _marker;
  bool _isMapInitialized = false;
  bool _isDisposed = false;

  // ValueNotifier를 통한 위치 변경 감지
  late final ValueNotifier<NLatLng> _positionNotifier;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _positionNotifier = ValueNotifier<NLatLng>(
      NLatLng(widget.latitude, widget.longitude),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _positionNotifier.dispose();
    if (_mapController != null) {
      // 맵 컨트롤러 정리
      _mapController = null;
      _marker = null;
      _isMapInitialized = false;
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 앱 생명주기 상태 변경 감지
    if (state == AppLifecycleState.resumed) {
      // 앱이 포그라운드로 돌아왔을 때 맵 재초기화
      if (_isMapInitialized && _mapController != null) {
        // 지도 다시 그리기 위해 상태 재설정
        setState(() {
          _isMapInitialized = false;
          _mapController = null;
          _marker = null;
        });
      }
    }
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
    // 맵이 초기화되지 않았거나 이미 dispose된 경우 아무 작업도 하지 않음
    if (!_isMapInitialized || _mapController == null || _isDisposed) return;

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
    // 앱이 포그라운드로 복귀했거나 초기 상태면 맵 새로 그리기
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
              if (_isDisposed) return;

              // 컨트롤러 저장 (이제 정적 변수가 아닌 인스턴스 변수로 저장)
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
    if (_mapController == null || _isDisposed) return;

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
