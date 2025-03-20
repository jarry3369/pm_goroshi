import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pmgoroshi/domain/entities/violation_type.dart';

part 'form_data.freezed.dart';
part 'form_data.g.dart';

@freezed
class SubmissionData with _$SubmissionData {
  const factory SubmissionData({
    required String qrData,
    required String description,
    required List<String> imagePaths,
    required DateTime submissionTime,
    required String location,
    double? latitude,
    double? longitude,
    required String companyName,
    String? serialNumber,
    @JsonKey(toJson: _violationTypeToJson) required ViolationType violationType,
  }) = _SubmissionData;

  factory SubmissionData.fromJson(Map<String, dynamic> json) =>
      _$SubmissionDataFromJson(json);
}

// violationType의 toJson을 처리하는 helper 함수
Map<String, dynamic>? _violationTypeToJson(ViolationType? violationType) {
  return violationType?.toJson();
}
