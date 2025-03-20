// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'form_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SubmissionDataImpl _$$SubmissionDataImplFromJson(Map<String, dynamic> json) =>
    _$SubmissionDataImpl(
      qrData: json['qrData'] as String,
      description: json['description'] as String,
      imagePaths: (json['imagePaths'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      submissionTime: DateTime.parse(json['submissionTime'] as String),
      location: json['location'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      companyName: json['companyName'] as String,
      serialNumber: json['serialNumber'] as String?,
      violationType:
          ViolationType.fromJson(json['violationType'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$SubmissionDataImplToJson(
        _$SubmissionDataImpl instance) =>
    <String, dynamic>{
      'qrData': instance.qrData,
      'description': instance.description,
      'imagePaths': instance.imagePaths,
      'submissionTime': instance.submissionTime.toIso8601String(),
      'location': instance.location,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'companyName': instance.companyName,
      'serialNumber': instance.serialNumber,
      'violationType': _violationTypeToJson(instance.violationType),
    };
