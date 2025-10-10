// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'banner.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Banner _$BannerFromJson(Map<String, dynamic> json) {
  return _Banner.fromJson(json);
}

/// @nodoc
mixin _$Banner {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  String? get image_url => throw _privateConstructorUsedError;
  bool get is_active => throw _privateConstructorUsedError;
  DateTime get start_date => throw _privateConstructorUsedError;
  DateTime? get end_date => throw _privateConstructorUsedError;
  int get priority => throw _privateConstructorUsedError;
  String? get action_url => throw _privateConstructorUsedError;
  String? get action_type => throw _privateConstructorUsedError;
  DateTime get timestamp =>
      throw _privateConstructorUsedError; // 클라이언트 측 필드 (데이터베이스에 없는 필드)
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get is_read => throw _privateConstructorUsedError;
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get do_not_show_again => throw _privateConstructorUsedError;
  @JsonKey(includeFromJson: false, includeToJson: false)
  BannerType get banner_type => throw _privateConstructorUsedError;
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get background_color => throw _privateConstructorUsedError;
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get button_text => throw _privateConstructorUsedError;
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get type_label => throw _privateConstructorUsedError;
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get sub_image_url => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $BannerCopyWith<Banner> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BannerCopyWith<$Res> {
  factory $BannerCopyWith(Banner value, $Res Function(Banner) then) =
      _$BannerCopyWithImpl<$Res, Banner>;
  @useResult
  $Res call(
      {String id,
      String title,
      String content,
      String? image_url,
      bool is_active,
      DateTime start_date,
      DateTime? end_date,
      int priority,
      String? action_url,
      String? action_type,
      DateTime timestamp,
      @JsonKey(includeFromJson: false, includeToJson: false) bool is_read,
      @JsonKey(includeFromJson: false, includeToJson: false)
      bool do_not_show_again,
      @JsonKey(includeFromJson: false, includeToJson: false)
      BannerType banner_type,
      @JsonKey(includeFromJson: false, includeToJson: false)
      String? background_color,
      @JsonKey(includeFromJson: false, includeToJson: false)
      String? button_text,
      @JsonKey(includeFromJson: false, includeToJson: false) String? type_label,
      @JsonKey(includeFromJson: false, includeToJson: false)
      String? sub_image_url});
}

/// @nodoc
class _$BannerCopyWithImpl<$Res, $Val extends Banner>
    implements $BannerCopyWith<$Res> {
  _$BannerCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? content = null,
    Object? image_url = freezed,
    Object? is_active = null,
    Object? start_date = null,
    Object? end_date = freezed,
    Object? priority = null,
    Object? action_url = freezed,
    Object? action_type = freezed,
    Object? timestamp = null,
    Object? is_read = null,
    Object? do_not_show_again = null,
    Object? banner_type = null,
    Object? background_color = freezed,
    Object? button_text = freezed,
    Object? type_label = freezed,
    Object? sub_image_url = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      image_url: freezed == image_url
          ? _value.image_url
          : image_url // ignore: cast_nullable_to_non_nullable
              as String?,
      is_active: null == is_active
          ? _value.is_active
          : is_active // ignore: cast_nullable_to_non_nullable
              as bool,
      start_date: null == start_date
          ? _value.start_date
          : start_date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      end_date: freezed == end_date
          ? _value.end_date
          : end_date // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      priority: null == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as int,
      action_url: freezed == action_url
          ? _value.action_url
          : action_url // ignore: cast_nullable_to_non_nullable
              as String?,
      action_type: freezed == action_type
          ? _value.action_type
          : action_type // ignore: cast_nullable_to_non_nullable
              as String?,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      is_read: null == is_read
          ? _value.is_read
          : is_read // ignore: cast_nullable_to_non_nullable
              as bool,
      do_not_show_again: null == do_not_show_again
          ? _value.do_not_show_again
          : do_not_show_again // ignore: cast_nullable_to_non_nullable
              as bool,
      banner_type: null == banner_type
          ? _value.banner_type
          : banner_type // ignore: cast_nullable_to_non_nullable
              as BannerType,
      background_color: freezed == background_color
          ? _value.background_color
          : background_color // ignore: cast_nullable_to_non_nullable
              as String?,
      button_text: freezed == button_text
          ? _value.button_text
          : button_text // ignore: cast_nullable_to_non_nullable
              as String?,
      type_label: freezed == type_label
          ? _value.type_label
          : type_label // ignore: cast_nullable_to_non_nullable
              as String?,
      sub_image_url: freezed == sub_image_url
          ? _value.sub_image_url
          : sub_image_url // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BannerImplCopyWith<$Res> implements $BannerCopyWith<$Res> {
  factory _$$BannerImplCopyWith(
          _$BannerImpl value, $Res Function(_$BannerImpl) then) =
      __$$BannerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      String content,
      String? image_url,
      bool is_active,
      DateTime start_date,
      DateTime? end_date,
      int priority,
      String? action_url,
      String? action_type,
      DateTime timestamp,
      @JsonKey(includeFromJson: false, includeToJson: false) bool is_read,
      @JsonKey(includeFromJson: false, includeToJson: false)
      bool do_not_show_again,
      @JsonKey(includeFromJson: false, includeToJson: false)
      BannerType banner_type,
      @JsonKey(includeFromJson: false, includeToJson: false)
      String? background_color,
      @JsonKey(includeFromJson: false, includeToJson: false)
      String? button_text,
      @JsonKey(includeFromJson: false, includeToJson: false) String? type_label,
      @JsonKey(includeFromJson: false, includeToJson: false)
      String? sub_image_url});
}

/// @nodoc
class __$$BannerImplCopyWithImpl<$Res>
    extends _$BannerCopyWithImpl<$Res, _$BannerImpl>
    implements _$$BannerImplCopyWith<$Res> {
  __$$BannerImplCopyWithImpl(
      _$BannerImpl _value, $Res Function(_$BannerImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? content = null,
    Object? image_url = freezed,
    Object? is_active = null,
    Object? start_date = null,
    Object? end_date = freezed,
    Object? priority = null,
    Object? action_url = freezed,
    Object? action_type = freezed,
    Object? timestamp = null,
    Object? is_read = null,
    Object? do_not_show_again = null,
    Object? banner_type = null,
    Object? background_color = freezed,
    Object? button_text = freezed,
    Object? type_label = freezed,
    Object? sub_image_url = freezed,
  }) {
    return _then(_$BannerImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      image_url: freezed == image_url
          ? _value.image_url
          : image_url // ignore: cast_nullable_to_non_nullable
              as String?,
      is_active: null == is_active
          ? _value.is_active
          : is_active // ignore: cast_nullable_to_non_nullable
              as bool,
      start_date: null == start_date
          ? _value.start_date
          : start_date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      end_date: freezed == end_date
          ? _value.end_date
          : end_date // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      priority: null == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as int,
      action_url: freezed == action_url
          ? _value.action_url
          : action_url // ignore: cast_nullable_to_non_nullable
              as String?,
      action_type: freezed == action_type
          ? _value.action_type
          : action_type // ignore: cast_nullable_to_non_nullable
              as String?,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      is_read: null == is_read
          ? _value.is_read
          : is_read // ignore: cast_nullable_to_non_nullable
              as bool,
      do_not_show_again: null == do_not_show_again
          ? _value.do_not_show_again
          : do_not_show_again // ignore: cast_nullable_to_non_nullable
              as bool,
      banner_type: null == banner_type
          ? _value.banner_type
          : banner_type // ignore: cast_nullable_to_non_nullable
              as BannerType,
      background_color: freezed == background_color
          ? _value.background_color
          : background_color // ignore: cast_nullable_to_non_nullable
              as String?,
      button_text: freezed == button_text
          ? _value.button_text
          : button_text // ignore: cast_nullable_to_non_nullable
              as String?,
      type_label: freezed == type_label
          ? _value.type_label
          : type_label // ignore: cast_nullable_to_non_nullable
              as String?,
      sub_image_url: freezed == sub_image_url
          ? _value.sub_image_url
          : sub_image_url // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BannerImpl with DiagnosticableTreeMixin implements _Banner {
  const _$BannerImpl(
      {required this.id,
      required this.title,
      required this.content,
      this.image_url,
      required this.is_active,
      required this.start_date,
      this.end_date,
      this.priority = 0,
      this.action_url,
      this.action_type,
      required this.timestamp,
      @JsonKey(includeFromJson: false, includeToJson: false)
      this.is_read = false,
      @JsonKey(includeFromJson: false, includeToJson: false)
      this.do_not_show_again = false,
      @JsonKey(includeFromJson: false, includeToJson: false)
      this.banner_type = BannerType.basic,
      @JsonKey(includeFromJson: false, includeToJson: false)
      this.background_color,
      @JsonKey(includeFromJson: false, includeToJson: false) this.button_text,
      @JsonKey(includeFromJson: false, includeToJson: false) this.type_label,
      @JsonKey(includeFromJson: false, includeToJson: false)
      this.sub_image_url});

  factory _$BannerImpl.fromJson(Map<String, dynamic> json) =>
      _$$BannerImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String content;
  @override
  final String? image_url;
  @override
  final bool is_active;
  @override
  final DateTime start_date;
  @override
  final DateTime? end_date;
  @override
  @JsonKey()
  final int priority;
  @override
  final String? action_url;
  @override
  final String? action_type;
  @override
  final DateTime timestamp;
// 클라이언트 측 필드 (데이터베이스에 없는 필드)
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final bool is_read;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final bool do_not_show_again;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final BannerType banner_type;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? background_color;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? button_text;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? type_label;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? sub_image_url;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'Banner(id: $id, title: $title, content: $content, image_url: $image_url, is_active: $is_active, start_date: $start_date, end_date: $end_date, priority: $priority, action_url: $action_url, action_type: $action_type, timestamp: $timestamp, is_read: $is_read, do_not_show_again: $do_not_show_again, banner_type: $banner_type, background_color: $background_color, button_text: $button_text, type_label: $type_label, sub_image_url: $sub_image_url)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'Banner'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('title', title))
      ..add(DiagnosticsProperty('content', content))
      ..add(DiagnosticsProperty('image_url', image_url))
      ..add(DiagnosticsProperty('is_active', is_active))
      ..add(DiagnosticsProperty('start_date', start_date))
      ..add(DiagnosticsProperty('end_date', end_date))
      ..add(DiagnosticsProperty('priority', priority))
      ..add(DiagnosticsProperty('action_url', action_url))
      ..add(DiagnosticsProperty('action_type', action_type))
      ..add(DiagnosticsProperty('timestamp', timestamp))
      ..add(DiagnosticsProperty('is_read', is_read))
      ..add(DiagnosticsProperty('do_not_show_again', do_not_show_again))
      ..add(DiagnosticsProperty('banner_type', banner_type))
      ..add(DiagnosticsProperty('background_color', background_color))
      ..add(DiagnosticsProperty('button_text', button_text))
      ..add(DiagnosticsProperty('type_label', type_label))
      ..add(DiagnosticsProperty('sub_image_url', sub_image_url));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BannerImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.image_url, image_url) ||
                other.image_url == image_url) &&
            (identical(other.is_active, is_active) ||
                other.is_active == is_active) &&
            (identical(other.start_date, start_date) ||
                other.start_date == start_date) &&
            (identical(other.end_date, end_date) ||
                other.end_date == end_date) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.action_url, action_url) ||
                other.action_url == action_url) &&
            (identical(other.action_type, action_type) ||
                other.action_type == action_type) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.is_read, is_read) || other.is_read == is_read) &&
            (identical(other.do_not_show_again, do_not_show_again) ||
                other.do_not_show_again == do_not_show_again) &&
            (identical(other.banner_type, banner_type) ||
                other.banner_type == banner_type) &&
            (identical(other.background_color, background_color) ||
                other.background_color == background_color) &&
            (identical(other.button_text, button_text) ||
                other.button_text == button_text) &&
            (identical(other.type_label, type_label) ||
                other.type_label == type_label) &&
            (identical(other.sub_image_url, sub_image_url) ||
                other.sub_image_url == sub_image_url));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      content,
      image_url,
      is_active,
      start_date,
      end_date,
      priority,
      action_url,
      action_type,
      timestamp,
      is_read,
      do_not_show_again,
      banner_type,
      background_color,
      button_text,
      type_label,
      sub_image_url);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BannerImplCopyWith<_$BannerImpl> get copyWith =>
      __$$BannerImplCopyWithImpl<_$BannerImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BannerImplToJson(
      this,
    );
  }
}

abstract class _Banner implements Banner {
  const factory _Banner(
      {required final String id,
      required final String title,
      required final String content,
      final String? image_url,
      required final bool is_active,
      required final DateTime start_date,
      final DateTime? end_date,
      final int priority,
      final String? action_url,
      final String? action_type,
      required final DateTime timestamp,
      @JsonKey(includeFromJson: false, includeToJson: false) final bool is_read,
      @JsonKey(includeFromJson: false, includeToJson: false)
      final bool do_not_show_again,
      @JsonKey(includeFromJson: false, includeToJson: false)
      final BannerType banner_type,
      @JsonKey(includeFromJson: false, includeToJson: false)
      final String? background_color,
      @JsonKey(includeFromJson: false, includeToJson: false)
      final String? button_text,
      @JsonKey(includeFromJson: false, includeToJson: false)
      final String? type_label,
      @JsonKey(includeFromJson: false, includeToJson: false)
      final String? sub_image_url}) = _$BannerImpl;

  factory _Banner.fromJson(Map<String, dynamic> json) = _$BannerImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get content;
  @override
  String? get image_url;
  @override
  bool get is_active;
  @override
  DateTime get start_date;
  @override
  DateTime? get end_date;
  @override
  int get priority;
  @override
  String? get action_url;
  @override
  String? get action_type;
  @override
  DateTime get timestamp;
  @override // 클라이언트 측 필드 (데이터베이스에 없는 필드)
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get is_read;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get do_not_show_again;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  BannerType get banner_type;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get background_color;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get button_text;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get type_label;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get sub_image_url;
  @override
  @JsonKey(ignore: true)
  _$$BannerImplCopyWith<_$BannerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
