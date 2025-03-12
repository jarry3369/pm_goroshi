// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ScanResultImpl _$$ScanResultImplFromJson(Map<String, dynamic> json) =>
    _$ScanResultImpl(
      qrData: json['qrData'] as String,
      scanTime: DateTime.parse(json['scanTime'] as String),
      location: json['location'] as String?,
    );

Map<String, dynamic> _$$ScanResultImplToJson(_$ScanResultImpl instance) =>
    <String, dynamic>{
      'qrData': instance.qrData,
      'scanTime': instance.scanTime.toIso8601String(),
      'location': instance.location,
    };
