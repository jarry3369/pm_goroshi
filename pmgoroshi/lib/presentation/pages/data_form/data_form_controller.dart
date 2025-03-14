import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pmgoroshi/domain/entities/form_data.dart';
import 'package:pmgoroshi/data/services/image_picker_service_impl.dart';
import 'package:pmgoroshi/presentation/pages/data_form/data_form_state.dart';
import 'package:pmgoroshi/data/services/api_service.dart'; // API 서비스 추가
import 'package:pmgoroshi/data/services/location_service.dart'; // 위치 서비스 추가
import 'package:pmgoroshi/domain/entities/violation_type.dart'; // 위반 유형 추가
import 'package:geolocator/geolocator.dart';

part 'data_form_controller.g.dart';

@riverpod
class DataFormController extends _$DataFormController {
  @override
  DataFormState build(String initialQrData) {
    // 컨트롤러 초기화 시 위치 정보 가져오기
    // 상태를 먼저 반환하고 비동기로 위치 정보를 가져옴
    final initialState = DataFormState.initial(initialQrData);

    // 위치 정보 로딩 상태로 설정
    state = initialState.copyWith(isLocationLoading: true);

    // 비동기로 위치 정보 가져오기
    _fetchCurrentLocation();

    return initialState.copyWith(isLocationLoading: true);
  }

  // 설명 업데이트
  void updateDescription(String description) {
    state = state.copyWith(description: description);
  }

  // 위반 유형 업데이트
  void updateViolationType(ViolationType violationType) {
    state = state.copyWith(violationType: violationType);
  }

  // 현재 위치 가져오기
  Future<void> _fetchCurrentLocation() async {
    try {
      final locationService = ref.read(locationServiceProvider);
      final position = await locationService.getCurrentPosition();

      if (position != null) {
        final address = await locationService.getFormattedAddress(position);
        state = state.copyWith(
          position: position,
          location: address,
          isLocationLoading: false,
        );
      } else {
        state = state.copyWith(
          isLocationLoading: false,
          errorMessage: '위치 정보를 가져올 수 없습니다. 위치 권한을 확인해주세요.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLocationLoading: false,
        errorMessage: '위치 정보를 가져오는 중 오류가 발생했습니다: ${e.toString()}',
      );
    }
  }

  // 위치 정보 새로고침
  Future<void> refreshLocation() async {
    state = state.copyWith(isLocationLoading: true, errorMessage: null);
    await _fetchCurrentLocation();
  }

  // 갤러리에서 이미지 선택
  Future<void> pickImageFromGallery() async {
    final imagePickerService = ref.read(imagePickerServiceProvider);
    final imagePath = await imagePickerService.pickImageFromGallery();

    if (imagePath != null) {
      state = state.copyWith(imagePaths: [...state.imagePaths, imagePath]);
    }
  }

  // 카메라로 이미지 촬영
  Future<void> pickImageFromCamera() async {
    final imagePickerService = ref.read(imagePickerServiceProvider);
    final imagePath = await imagePickerService.pickImageFromCamera();

    if (imagePath != null) {
      state = state.copyWith(imagePaths: [...state.imagePaths, imagePath]);
    }
  }

  // 이미지 제거
  void removeImage(int index) {
    final updatedImages = List<String>.from(state.imagePaths);
    if (index >= 0 && index < updatedImages.length) {
      updatedImages.removeAt(index);
      state = state.copyWith(imagePaths: updatedImages);
    }
  }

  // 폼 제출
  Future<SubmissionData?> submitForm() async {
    if (state.description.isEmpty) {
      state = state.copyWith(errorMessage: '설명을 입력해주세요');
      return null;
    }

    if (state.violationType == null) {
      state = state.copyWith(errorMessage: '위반 유형을 선택해주세요');
      return null;
    }

    // 제출 시작
    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      // SubmissionData 생성
      final submissionData = SubmissionData(
        qrData: state.qrData,
        description: state.description,
        imagePaths: state.imagePaths.isEmpty ? null : state.imagePaths,
        submissionTime: DateTime.now(),
        location: state.location,
        violationType: state.violationType,
      );

      // API 서비스를 통한 실제 서버 통신
      // 실제 서버가 없으므로 주석 처리된 코드
      /*
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.submitFormData(submissionData);
      */

      // 개발 중에는 딜레이로 API 호출 시뮬레이션
      await Future.delayed(const Duration(seconds: 1));

      // 제출 성공
      state = state.copyWith(isSubmitting: false, isSuccess: true);

      return submissionData;
    } catch (e) {
      // 제출 실패
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: '데이터 제출에 실패했습니다. 다시 시도해주세요.',
      );
      return null;
    }
  }

  // 폼 초기화
  void resetForm() {
    state = DataFormState.initial(state.qrData);
    _fetchCurrentLocation();
  }
}
