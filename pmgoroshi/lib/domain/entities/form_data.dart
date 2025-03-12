import 'package:freezed_annotation/freezed_annotation.dart';

part 'form_data.freezed.dart';
part 'form_data.g.dart';

// FormData -> SubmissionData로 이름 변경
@freezed
class SubmissionData with _$SubmissionData {
  const factory SubmissionData({
    required String qrData,
    required String description,
    List<String>? imagePaths,
    DateTime? submissionTime,
    String? location,
  }) = _SubmissionData;

  factory SubmissionData.fromJson(Map<String, dynamic> json) =>
      _$SubmissionDataFromJson(json);
}
