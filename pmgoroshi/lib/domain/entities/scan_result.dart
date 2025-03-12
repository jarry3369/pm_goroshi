import 'package:freezed_annotation/freezed_annotation.dart';

part 'scan_result.freezed.dart';
part 'scan_result.g.dart';

@freezed
class ScanResult with _$ScanResult {
  const factory ScanResult({
    required String qrData,
    required DateTime scanTime,
    String? location,
  }) = _ScanResult;

  factory ScanResult.fromJson(Map<String, dynamic> json) =>
      _$ScanResultFromJson(json);
}
