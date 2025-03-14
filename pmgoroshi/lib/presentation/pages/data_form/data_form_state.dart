import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pmgoroshi/domain/entities/form_data.dart';
import 'package:pmgoroshi/domain/entities/violation_type.dart';
import 'package:geolocator/geolocator.dart';

part 'data_form_state.freezed.dart';

@freezed
class DataFormState with _$DataFormState {
  const factory DataFormState({
    required String qrData,
    required String description,
    @Default([]) List<String> imagePaths,
    @Default(false) bool isSubmitting,
    @Default(false) bool isSuccess,
    String? errorMessage,
    String? location,
    Position? position,
    ViolationType? violationType,
    @Default(false) bool isLocationLoading,
  }) = _DataFormState;

  factory DataFormState.initial(String qrData) =>
      DataFormState(qrData: qrData, description: '');
}
