import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pmgoroshi/domain/entities/form_data.dart';
import 'package:pmgoroshi/data/services/image_picker_service_impl.dart';
import 'package:pmgoroshi/presentation/pages/data_form/data_form_state.dart';
import 'package:pmgoroshi/data/services/api_service.dart'; // API 서비스 추가
import 'package:pmgoroshi/data/services/location_service.dart'; // 위치 서비스 추가
import 'package:pmgoroshi/domain/entities/violation_type.dart'; // 위반 유형 추가
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pmgoroshi/data/services/supabase_service.dart'; // Supabase 서비스 추가

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

  // 설명 업데이트 - 디바운스 적용으로 잦은 상태 업데이트 방지
  String? _lastDescription;
  Future<void>? _pendingDescriptionUpdate;

  void updateDescription(String description) {
    // 동일한 설명이면 업데이트 하지 않음
    if (_lastDescription == description) return;
    _lastDescription = description;

    // 기존 대기 중인 업데이트가 있으면 취소
    _pendingDescriptionUpdate?.whenComplete(() {});

    // 300ms 딜레이 후 업데이트 실행 (타이핑 중에는 업데이트하지 않음)
    _pendingDescriptionUpdate = Future.delayed(
      const Duration(milliseconds: 300),
      () {
        if (_lastDescription == description) {
          state = state.copyWith(description: description);
        }
      },
    );
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

        // 위치 정보가 변경된 경우에만 상태 업데이트
        if (state.position == null ||
            state.position!.latitude != position.latitude ||
            state.position!.longitude != position.longitude) {
          state = state.copyWith(
            position: position,
            location: address,
            isLocationLoading: false,
          );
        } else {
          // 위치는 같지만 로딩 상태만 변경
          state = state.copyWith(isLocationLoading: false);
        }
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
    // 이미 로딩 중이면 중복 요청 방지
    if (state.isLocationLoading) return;

    // 로딩 상태만 변경하고, 다른 상태는 그대로 유지
    state = state.copyWith(isLocationLoading: true, errorMessage: null);

    try {
      final locationService = ref.read(locationServiceProvider);
      final position = await locationService.getCurrentPosition();

      if (position != null) {
        final address = await locationService.getFormattedAddress(position);

        // 위치 정보가 변경된 경우에만 모든 상태 업데이트
        if (state.position == null ||
            state.position!.latitude != position.latitude ||
            state.position!.longitude != position.longitude) {
          state = state.copyWith(
            position: position,
            location: address,
            isLocationLoading: false,
          );
        } else {
          // 위치가 동일한 경우, 로딩 상태만 업데이트
          state = state.copyWith(isLocationLoading: false);
        }
      } else {
        // 위치 정보를 가져오지 못한 경우
        state = state.copyWith(
          isLocationLoading: false,
          errorMessage: '위치 정보를 가져올 수 없습니다. 위치 권한을 확인해주세요.',
        );
      }
    } catch (e) {
      // 오류 발생 시
      state = state.copyWith(
        isLocationLoading: false,
        errorMessage: '위치 정보를 가져오는 중 오류가 발생했습니다: ${e.toString()}',
      );
    }
  }

  // 이미지 추가 최적화
  void _updateImagePaths(List<String> newImagePaths) {
    // 리스트 비교를 통해 변경점이 있는 경우에만 상태 업데이트
    if (state.imagePaths.length != newImagePaths.length ||
        !state.imagePaths.every((path) => newImagePaths.contains(path))) {
      state = state.copyWith(imagePaths: newImagePaths);
    }
  }

  // 갤러리에서 이미지 선택
  Future<void> pickImageFromGallery() async {
    final imagePickerService = ref.read(imagePickerServiceProvider);
    final imagePath = await imagePickerService.pickImageFromGallery();

    if (imagePath != null) {
      final updatedImagePaths = [...state.imagePaths, imagePath];
      _updateImagePaths(updatedImagePaths);
    }
  }

  // 카메라로 이미지 촬영
  Future<void> pickImageFromCamera() async {
    final imagePickerService = ref.read(imagePickerServiceProvider);
    final imagePath = await imagePickerService.pickImageFromCamera();

    if (imagePath != null) {
      final updatedImagePaths = [...state.imagePaths, imagePath];
      _updateImagePaths(updatedImagePaths);
    }
  }

  // 이미지 제거
  void removeImage(int index) {
    if (index < 0 || index >= state.imagePaths.length) return;

    final updatedImages = List<String>.from(state.imagePaths);
    updatedImages.removeAt(index);
    _updateImagePaths(updatedImages);
  }

  // QR 코드 데이터 파싱 함수
  Future<(String companyName, String? serialNumber)> parseQrData(
    String qrData,
  ) async {
    try {
      final supabaseService = SupabaseService();
      final companyMappings = await supabaseService.getCompanyMapping();

      final uri = Uri.parse(qrData);
      final host = uri.host.toLowerCase();

      String companyName = '알 수 없는 업체';
      String? serialNumber;

      for (final entry in companyMappings.entries) {
        final code = entry.key.toLowerCase();
        if (host == code || host.contains(code)) {
          companyName = entry.value['name'];

          final qk = entry.value['qk'];

          if (qk != null) {
            if (qk == 'pathSegments') {
              serialNumber = uri.pathSegments.last;
            } else {
              serialNumber = uri.queryParameters[qk];
            }
          } else {
            serialNumber = uri.queryParameters.values.first;
          }

          break;
        }
      }

      return (companyName, serialNumber);
    } catch (e) {
      debugPrint('QR 코드 파싱 오류: $e');
      return ('유효하지 않은 URL', null);
    }
  }

  // 폼 제출
  Future<SubmissionData?> submitForm() async {
    // 모든 필수 필드 유효성 검사
    if (state.description.isEmpty) {
      state = state.copyWith(errorMessage: '설명을 입력해주세요');
      return null;
    }

    if (state.violationType == null) {
      state = state.copyWith(errorMessage: '위반 유형을 선택해주세요');
      return null;
    }

    if (state.location == null || state.position == null) {
      state = state.copyWith(
        errorMessage: '위치 정보를 가져오는데 실패했습니다. 위치 정보를 새로고침해주세요.',
      );
      return null;
    }

    if (state.imagePaths.isEmpty) {
      state = state.copyWith(errorMessage: '최소 한 장 이상의 사진을 첨부해주세요');
      return null;
    }

    // QR 코드에서 업체명과 시리얼 번호 추출
    final (companyName, serialNumber) = await parseQrData(state.qrData);

    // if (serialNumber == null) {
    //   state = state.copyWith(
    //     errorMessage: '유효한 시리얼 번호를 찾을 수 없습니다. QR 코드를 다시 스캔해주세요.',
    //   );
    //   return null;
    // }

    // 제출 시작
    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      // SubmissionData 생성
      final submissionData = SubmissionData(
        qrData: state.qrData,
        description: state.description,
        imagePaths: state.imagePaths,
        submissionTime: DateTime.now(),
        location: state.location!,
        violationType: state.violationType!,
        companyName: companyName,
        serialNumber: serialNumber,
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
        errorMessage: '제출 중 오류가 발생했습니다: ${e.toString()}',
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
