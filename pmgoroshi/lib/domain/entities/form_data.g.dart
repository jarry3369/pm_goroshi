// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'form_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SubmissionDataImpl _$$SubmissionDataImplFromJson(Map<String, dynamic> json) =>
    _$SubmissionDataImpl(
      qrData: json['qrData'] as String,
      description: json['description'] as String,
      imagePaths: (json['imagePaths'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      submissionTime: json['submissionTime'] == null
          ? null
          : DateTime.parse(json['submissionTime'] as String),
      location: json['location'] as String?,
    );

Map<String, dynamic> _$$SubmissionDataImplToJson(
        _$SubmissionDataImpl instance) =>
    <String, dynamic>{
      'qrData': instance.qrData,
      'description': instance.description,
      'imagePaths': instance.imagePaths,
      'submissionTime': instance.submissionTime?.toIso8601String(),
      'location': instance.location,
    };
