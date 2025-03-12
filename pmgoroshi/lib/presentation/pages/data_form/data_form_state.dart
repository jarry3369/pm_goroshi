import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pmgoroshi/domain/entities/form_data.dart';

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
  }) = _DataFormState;

  factory DataFormState.initial(String qrData) =>
      DataFormState(qrData: qrData, description: '');
}
