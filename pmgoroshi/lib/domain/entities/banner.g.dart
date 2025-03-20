// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'banner.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BannerImpl _$$BannerImplFromJson(Map<String, dynamic> json) => _$BannerImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      image_url: json['image_url'] as String?,
      is_active: json['is_active'] as bool,
      start_date: DateTime.parse(json['start_date'] as String),
      end_date: json['end_date'] == null
          ? null
          : DateTime.parse(json['end_date'] as String),
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      action_url: json['action_url'] as String?,
      action_type: json['action_type'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$$BannerImplToJson(_$BannerImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'content': instance.content,
      'image_url': instance.image_url,
      'is_active': instance.is_active,
      'start_date': instance.start_date.toIso8601String(),
      'end_date': instance.end_date?.toIso8601String(),
      'priority': instance.priority,
      'action_url': instance.action_url,
      'action_type': instance.action_type,
      'timestamp': instance.timestamp.toIso8601String(),
    };
