import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/foundation.dart';

part 'banner.freezed.dart';
part 'banner.g.dart';

@JsonEnum()
enum BannerType {
  basic, // 기본형
  video, // 동영상형
  image, // 이미지형
  cinema, // 시네마형
}

@freezed
class Banner with _$Banner {
  const factory Banner({
    required String id,
    required String title,
    required String content,
    String? image_url,
    required bool is_active,
    required DateTime start_date,
    DateTime? end_date,
    @Default(0) int priority,
    String? action_url,
    String? action_type,
    required DateTime timestamp,

    // 클라이언트 측 필드 (데이터베이스에 없는 필드)
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default(false)
    bool is_read,
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default(false)
    bool do_not_show_again,
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default(BannerType.basic)
    BannerType banner_type,
    @JsonKey(includeFromJson: false, includeToJson: false)
    String? background_color,
    @JsonKey(includeFromJson: false, includeToJson: false) String? button_text,
    @JsonKey(includeFromJson: false, includeToJson: false) String? type_label,
    @JsonKey(includeFromJson: false, includeToJson: false)
    String? sub_image_url,
  }) = _Banner;

  factory Banner.fromJson(Map<String, dynamic> json) => _$BannerFromJson(json);
}
