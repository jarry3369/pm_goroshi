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
    // 최대 이미지 개수 제한 (5장)
    const int maxImages = 5;

    // 최대 개수를 초과하는 경우 잘라내기
    if (newImagePaths.length > maxImages) {
      newImagePaths = newImagePaths.sublist(0, maxImages);
    }

    // 리스트 비교를 통해 변경점이 있는 경우에만 상태 업데이트
    if (state.imagePaths.length != newImagePaths.length ||
        !state.imagePaths.every((path) => newImagePaths.contains(path))) {
      state = state.copyWith(imagePaths: newImagePaths);
    }
  }

  // 갤러리에서 여러 이미지 선택
  Future<void> pickMultipleImagesFromGallery() async {
    // 최대 이미지 개수
    const int maxImages = 5;

    // 현재 이미지 개수가 이미 최대치인 경우
    if (state.imagePaths.length >= maxImages) {
      return;
    }

    // 로딩 상태 설정
    state = state.copyWith(isImageLoading: true);

    try {
      final imagePickerService = ref.read(imagePickerServiceProvider);
      final newImagePaths =
          await imagePickerService.pickMultipleImagesFromGallery();

      // 선택한 이미지가 없으면 종료
      if (newImagePaths.isEmpty) {
        state = state.copyWith(isImageLoading: false);
        return;
      }

      // 현재 이미지 수와 새로 선택한 이미지 수의 합이 최대치를 초과하는지 확인
      final remainingSlots = maxImages - state.imagePaths.length;

      // 현재 이미지에 새로운 이미지 추가 (최대 remainingSlots개까지만)
      final updatedImagePaths = [
        ...state.imagePaths,
        ...newImagePaths.take(remainingSlots),
      ];

      _updateImagePaths(updatedImagePaths);

      // 이미지 선택 완료 후 로딩 상태 해제
      state = state.copyWith(isImageLoading: false);
    } catch (e) {
      // 에러 발생 시 로딩 상태 해제
      state = state.copyWith(isImageLoading: false);
    }
  }

  // 갤러리에서 이미지 선택
  Future<void> pickImageFromGallery() async {
    // 이미지 개수 체크
    const int maxImages = 5;
    if (state.imagePaths.length >= maxImages) {
      return; // 이미 최대 개수면 아무 작업도 하지 않음
    }

    final imagePickerService = ref.read(imagePickerServiceProvider);
    final imagePath = await imagePickerService.pickImageFromGallery();

    if (imagePath != null) {
      final updatedImagePaths = [...state.imagePaths, imagePath];
      _updateImagePaths(updatedImagePaths);
    }
  }

  // 카메라로 이미지 촬영
  Future<void> pickImageFromCamera() async {
    // 이미지 개수 체크
    const int maxImages = 5;
    if (state.imagePaths.length >= maxImages) {
      return; // 이미 최대 개수면 아무 작업도 하지 않음
    }

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

  // QR 코드 데이터 파싱해서 회사명과 시리얼 번호 추출
  Future<(String companyName, String? serialNumber)> parseQrData(
    String qrData,
  ) async {
    try {
      // 직접 입력 모드 확인
      if (qrData.startsWith('direct_input:')) {
        return ('회사를 선택해주세요', null);
      }
      
      // 수동 선택된 회사명 확인
      if (qrData.startsWith('manual_selected:')) {
        // manual_selected: 접두사 제거하고 직접 선택된 회사명 사용
        final companyName = qrData.substring('manual_selected:'.length);
        return (companyName, null);
      }

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

  // 회사 목록 조회 (중복 제거된 목록)
  Future<List<String>> getCompanyList() async {
    try {
      final supabaseService = SupabaseService();
      final companyMappings = await supabaseService.getCompanyMapping();
      
      // 회사명 목록 추출 (중복 제거)
      final companyNames = companyMappings.entries
          .map((e) => e.value['name'] as String)
          .toSet() // Set으로 변환하여 중복 제거
          .toList();
      
      // 알파벳 순 정렬
      companyNames.sort();
      
      return companyNames;
    } catch (e) {
      debugPrint('회사 목록 조회 오류: $e');
      return [];
    }
  }
  
  // 회사명 선택 업데이트
  void updateSelectedCompany(String companyName) {
    debugPrint('회사 선택: $companyName');
    
    // 상태 업데이트 (qrData 변경)
    final newQrData = 'manual_selected:$companyName';
    state = state.copyWith(
      qrData: newQrData,
      // 다른 정보들 초기화 (필요에 따라 조정)
      imagePaths: state.imagePaths,
      position: state.position,
      location: state.location,
      description: state.description,
      violationType: state.violationType,
      errorMessage: null,
    );
    
    // 직접 상태 변경 후 상태를 리빌드하기 위해 강제로 상태 재설정
    state = state;
  }

  // 폼 제출
  Future<({bool isSuccess, SubmissionData? data, String? errorMessage})>
  submitForm() async {
    // 이미 제출 중이면 중복 요청 방지
    if (state.isSubmitting) {
      return (isSuccess: false, data: null, errorMessage: '이미 제출 중입니다.');
    }

    // 모든 필수 필드 유효성 검사

    if (state.violationType == null) {
      state = state.copyWith(errorMessage: '위반 유형을 선택해주세요');
      throw state;
    }

    if (state.description.isEmpty) {
      state = state.copyWith(errorMessage: '설명을 입력해주세요');
      throw state;
    }

    if (state.location == null || state.position == null) {
      final errorMsg = '위치 정보를 가져오는데 실패했습니다. 위치 정보를 새로고침해주세요.';
      state = state.copyWith(errorMessage: errorMsg);
      throw state;
    }

    if (state.imagePaths.isEmpty) {
      state = state.copyWith(errorMessage: '최소 한 장 이상의 사진을 첨부해주세요');
      throw state;
    }

    // QR 코드에서 업체명과 시리얼 번호 추출
    final (companyName, serialNumber) = await parseQrData(state.qrData);

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

      // Supabase 서비스 생성
      final supabaseService = SupabaseService();

      // 이미지 업로드
      if (state.imagePaths.isNotEmpty) {
        try {
          final uploadedImageUrls = await supabaseService.uploadImages(
            state.imagePaths,
          );

          // 업로드된 이미지 URL로 업데이트된 데이터 생성
          final updatedData = SubmissionData(
            qrData: submissionData.qrData,
            description: submissionData.description,
            imagePaths: uploadedImageUrls, // 업로드된 URL로 업데이트
            submissionTime: submissionData.submissionTime,
            location: submissionData.location,
            violationType: submissionData.violationType,
            companyName: submissionData.companyName,
            serialNumber: submissionData.serialNumber,
          );

          // Supabase에 데이터 저장
          await supabaseService.saveReportData(updatedData);

          // 제출 성공
          state = state.copyWith(isSubmitting: false, isSuccess: true);

          return (isSuccess: true, data: updatedData, errorMessage: null);
        } catch (e) {
          // 업로드 실패
          final errorMsg = '업로드 중 오류가 발생했습니다: ${e.toString()}';
          state = state.copyWith(isSubmitting: false, errorMessage: errorMsg);
          return (isSuccess: false, data: null, errorMessage: errorMsg);
        }
      } else {
        // 이미지가 없는 경우 (이미 위에서 체크하므로 여기로 오지 않음)
        await supabaseService.saveReportData(submissionData);

        // 제출 성공
        state = state.copyWith(isSubmitting: false, isSuccess: true);

        return (isSuccess: true, data: submissionData, errorMessage: null);
      }
    } catch (e) {
      // 제출 실패
      final errorMsg = '제출 중 오류가 발생했습니다: ${e.toString()}';
      state = state.copyWith(isSubmitting: false, errorMessage: errorMsg);
      return (isSuccess: false, data: null, errorMessage: errorMsg);
    }
  }

  // 폼 초기화
  void resetForm() {
    state = DataFormState.initial(state.qrData);
    _fetchCurrentLocation();
  }
}
