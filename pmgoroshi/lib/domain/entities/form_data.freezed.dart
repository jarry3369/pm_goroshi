// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'form_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SubmissionData _$SubmissionDataFromJson(Map<String, dynamic> json) {
  return _SubmissionData.fromJson(json);
}

/// @nodoc
mixin _$SubmissionData {
  String get qrData => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  List<String>? get imagePaths => throw _privateConstructorUsedError;
  DateTime? get submissionTime => throw _privateConstructorUsedError;
  String? get location => throw _privateConstructorUsedError;
  ViolationType? get violationType => throw _privateConstructorUsedError;

  /// Serializes this SubmissionData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SubmissionData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SubmissionDataCopyWith<SubmissionData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SubmissionDataCopyWith<$Res> {
  factory $SubmissionDataCopyWith(
          SubmissionData value, $Res Function(SubmissionData) then) =
      _$SubmissionDataCopyWithImpl<$Res, SubmissionData>;
  @useResult
  $Res call(
      {String qrData,
      String description,
      List<String>? imagePaths,
      DateTime? submissionTime,
      String? location,
      ViolationType? violationType});

  $ViolationTypeCopyWith<$Res>? get violationType;
}

/// @nodoc
class _$SubmissionDataCopyWithImpl<$Res, $Val extends SubmissionData>
    implements $SubmissionDataCopyWith<$Res> {
  _$SubmissionDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SubmissionData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? qrData = null,
    Object? description = null,
    Object? imagePaths = freezed,
    Object? submissionTime = freezed,
    Object? location = freezed,
    Object? violationType = freezed,
  }) {
    return _then(_value.copyWith(
      qrData: null == qrData
          ? _value.qrData
          : qrData // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      imagePaths: freezed == imagePaths
          ? _value.imagePaths
          : imagePaths // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      submissionTime: freezed == submissionTime
          ? _value.submissionTime
          : submissionTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as String?,
      violationType: freezed == violationType
          ? _value.violationType
          : violationType // ignore: cast_nullable_to_non_nullable
              as ViolationType?,
    ) as $Val);
  }

  /// Create a copy of SubmissionData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ViolationTypeCopyWith<$Res>? get violationType {
    if (_value.violationType == null) {
      return null;
    }

    return $ViolationTypeCopyWith<$Res>(_value.violationType!, (value) {
      return _then(_value.copyWith(violationType: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SubmissionDataImplCopyWith<$Res>
    implements $SubmissionDataCopyWith<$Res> {
  factory _$$SubmissionDataImplCopyWith(_$SubmissionDataImpl value,
          $Res Function(_$SubmissionDataImpl) then) =
      __$$SubmissionDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String qrData,
      String description,
      List<String>? imagePaths,
      DateTime? submissionTime,
      String? location,
      ViolationType? violationType});

  @override
  $ViolationTypeCopyWith<$Res>? get violationType;
}

/// @nodoc
class __$$SubmissionDataImplCopyWithImpl<$Res>
    extends _$SubmissionDataCopyWithImpl<$Res, _$SubmissionDataImpl>
    implements _$$SubmissionDataImplCopyWith<$Res> {
  __$$SubmissionDataImplCopyWithImpl(
      _$SubmissionDataImpl _value, $Res Function(_$SubmissionDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of SubmissionData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? qrData = null,
    Object? description = null,
    Object? imagePaths = freezed,
    Object? submissionTime = freezed,
    Object? location = freezed,
    Object? violationType = freezed,
  }) {
    return _then(_$SubmissionDataImpl(
      qrData: null == qrData
          ? _value.qrData
          : qrData // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      imagePaths: freezed == imagePaths
          ? _value._imagePaths
          : imagePaths // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      submissionTime: freezed == submissionTime
          ? _value.submissionTime
          : submissionTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as String?,
      violationType: freezed == violationType
          ? _value.violationType
          : violationType // ignore: cast_nullable_to_non_nullable
              as ViolationType?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SubmissionDataImpl implements _SubmissionData {
  const _$SubmissionDataImpl(
      {required this.qrData,
      required this.description,
      final List<String>? imagePaths,
      this.submissionTime,
      this.location,
      this.violationType})
      : _imagePaths = imagePaths;

  factory _$SubmissionDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$SubmissionDataImplFromJson(json);

  @override
  final String qrData;
  @override
  final String description;
  final List<String>? _imagePaths;
  @override
  List<String>? get imagePaths {
    final value = _imagePaths;
    if (value == null) return null;
    if (_imagePaths is EqualUnmodifiableListView) return _imagePaths;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final DateTime? submissionTime;
  @override
  final String? location;
  @override
  final ViolationType? violationType;

  @override
  String toString() {
    return 'SubmissionData(qrData: $qrData, description: $description, imagePaths: $imagePaths, submissionTime: $submissionTime, location: $location, violationType: $violationType)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SubmissionDataImpl &&
            (identical(other.qrData, qrData) || other.qrData == qrData) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality()
                .equals(other._imagePaths, _imagePaths) &&
            (identical(other.submissionTime, submissionTime) ||
                other.submissionTime == submissionTime) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.violationType, violationType) ||
                other.violationType == violationType));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      qrData,
      description,
      const DeepCollectionEquality().hash(_imagePaths),
      submissionTime,
      location,
      violationType);

  /// Create a copy of SubmissionData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SubmissionDataImplCopyWith<_$SubmissionDataImpl> get copyWith =>
      __$$SubmissionDataImplCopyWithImpl<_$SubmissionDataImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SubmissionDataImplToJson(
      this,
    );
  }
}

abstract class _SubmissionData implements SubmissionData {
  const factory _SubmissionData(
      {required final String qrData,
      required final String description,
      final List<String>? imagePaths,
      final DateTime? submissionTime,
      final String? location,
      final ViolationType? violationType}) = _$SubmissionDataImpl;

  factory _SubmissionData.fromJson(Map<String, dynamic> json) =
      _$SubmissionDataImpl.fromJson;

  @override
  String get qrData;
  @override
  String get description;
  @override
  List<String>? get imagePaths;
  @override
  DateTime? get submissionTime;
  @override
  String? get location;
  @override
  ViolationType? get violationType;

  /// Create a copy of SubmissionData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SubmissionDataImplCopyWith<_$SubmissionDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
