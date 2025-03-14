import 'package:freezed_annotation/freezed_annotation.dart';

part 'violation_type.freezed.dart';
part 'violation_type.g.dart';

@freezed
class ViolationType with _$ViolationType {
  const factory ViolationType({required int id, required String name}) =
      _ViolationType;

  factory ViolationType.fromJson(Map<String, dynamic> json) =>
      _$ViolationTypeFromJson(json);
}

// 위반 유형 목록
final List<ViolationType> violationTypes = [
  const ViolationType(id: 1, name: '보도와 차도가 구분된 도로의 차도'),
  const ViolationType(id: 2, name: '자전거 도로'),
  const ViolationType(id: 3, name: '지하철역 전면(5m이내)'),
  const ViolationType(id: 4, name: '버스정류소 및 택시승강장 주변(5m 이내)'),
  const ViolationType(id: 5, name: '횡단보도 주변(3m)'),
  const ViolationType(id: 6, name: '교통섬 내부'),
  const ViolationType(id: 7, name: '점자블록 또는 교통약자 엘리베이터'),
  const ViolationType(id: 8, name: '보호구역(어린이·노인·장애인)'),
  const ViolationType(id: 9, name: '그 외 지역'),
];
