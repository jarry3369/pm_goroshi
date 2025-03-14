import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pmgoroshi/presentation/pages/data_form/data_form_controller.dart';
import 'package:pmgoroshi/domain/entities/form_data.dart';
import 'package:pmgoroshi/domain/entities/violation_type.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

class DataFormPage extends ConsumerWidget {
  const DataFormPage({super.key, required this.qrData});

  final String qrData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dataFormControllerProvider(qrData));
    final controller = ref.read(dataFormControllerProvider(qrData).notifier);

    // 포커스 노드 생성
    final FocusNode focusNode = FocusNode();

    // 제출 성공 시 완료 화면으로 이동
    ref.listen(dataFormControllerProvider(qrData).select((s) => s.isSuccess), (
      previous,
      isSuccess,
    ) {
      if (isSuccess && previous == false) {
        final submissionData = SubmissionData(
          qrData: state.qrData,
          description: state.description,
          imagePaths: state.imagePaths,
          submissionTime: DateTime.now(),
          location: state.location,
          violationType: state.violationType,
        );

        context.go('/completion', extra: submissionData.toJson());
      }
    });

    return GestureDetector(
      // 화면의 빈 공간을 터치하면 포커스 해제
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('데이터 입력'), centerTitle: true),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQRDataSection(context, state.qrData),
                const SizedBox(height: 24),
                _buildLocationSection(context, state, controller),
                const SizedBox(height: 24),
                _buildViolationTypeSection(context, state, controller),
                const SizedBox(height: 24),
                _buildDescriptionField(context, state, controller, focusNode),
                const SizedBox(height: 24),
                _buildImagePickerSection(context, state, controller),
                const SizedBox(height: 32),
                if (state.errorMessage != null)
                  _buildErrorMessage(context, state.errorMessage!),
                const SizedBox(height: 16),
                _buildSubmitButton(context, state, controller),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQRDataSection(BuildContext context, String qrData) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'QR 코드 데이터',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SelectableText(
              qrData,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  // 위치 정보 섹션
  Widget _buildLocationSection(
    BuildContext context,
    dynamic state,
    DataFormController controller,
  ) {
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
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed:
                      state.isLocationLoading
                          ? null
                          : () => controller.refreshLocation(),
                  tooltip: '위치 새로고침',
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (state.isLocationLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (state.position != null)
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

                  // 네이버 지도 표시
                  SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: NaverMap(
                        options: NaverMapViewOptions(
                          initialCameraPosition: NCameraPosition(
                            target: NLatLng(
                              state.position!.latitude,
                              state.position!.longitude,
                            ),
                            zoom: 15,
                          ),
                          mapType: NMapType.basic,
                          nightModeEnable: false,
                          locationButtonEnable: true,
                        ),
                        onMapReady: (controller) {
                          // 마커 추가
                          controller.addOverlay(
                            NMarker(
                              id: 'current-location',
                              position: NLatLng(
                                state.position!.latitude,
                                state.position!.longitude,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              )
            else
              OutlinedButton.icon(
                onPressed: () => controller.refreshLocation(),
                icon: const Icon(Icons.location_on),
                label: const Text('위치 정보 가져오기'),
              ),
          ],
        ),
      ),
    );
  }

  // 위반 유형 선택 섹션
  Widget _buildViolationTypeSection(
    BuildContext context,
    dynamic state,
    DataFormController controller,
  ) {
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
              value: state.violationType,
              isExpanded: true,
              items:
                  violationTypes.map((type) {
                    return DropdownMenuItem<ViolationType>(
                      value: type,
                      child: Text(
                        '${type.id}. ${type.name}',
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

  Widget _buildDescriptionField(
    BuildContext context,
    dynamic state,
    DataFormController controller,
    FocusNode focusNode,
  ) {
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
          initialValue: state.description,
          onChanged: controller.updateDescription,
          maxLines: 4,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: '상세 내용을 입력하세요',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePickerSection(
    BuildContext context,
    dynamic state,
    DataFormController controller,
  ) {
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
        if (state.imagePaths.isNotEmpty)
          _buildImagePreviewGrid(context, state, controller),
      ],
    );
  }

  Widget _buildImagePreviewGrid(
    BuildContext context,
    dynamic state,
    DataFormController controller,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: state.imagePaths.length,
      itemBuilder: (context, index) {
        final imagePath = state.imagePaths[index];
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
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildErrorMessage(BuildContext context, String errorMessage) {
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

  Widget _buildSubmitButton(
    BuildContext context,
    dynamic state,
    DataFormController controller,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: state.isSubmitting ? null : () => controller.submitForm(),
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
