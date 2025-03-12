import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pmgoroshi/domain/entities/form_data.dart';
import 'package:pmgoroshi/data/services/image_picker_service_impl.dart';
import 'package:pmgoroshi/presentation/pages/data_form/data_form_state.dart';
import 'package:pmgoroshi/data/services/api_service.dart'; // API 서비스 추가

part 'data_form_controller.g.dart';

@riverpod
class DataFormController extends _$DataFormController {
  @override
  DataFormState build(String initialQrData) {
    return DataFormState.initial(initialQrData);
  }

  // 설명 업데이트
  void updateDescription(String description) {
    state = state.copyWith(description: description);
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
  }
}
