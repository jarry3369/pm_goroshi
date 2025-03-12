// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'data_form_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$DataFormState {
  String get qrData => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  List<String> get imagePaths => throw _privateConstructorUsedError;
  bool get isSubmitting => throw _privateConstructorUsedError;
  bool get isSuccess => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;
  String? get location => throw _privateConstructorUsedError;

  /// Create a copy of DataFormState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DataFormStateCopyWith<DataFormState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DataFormStateCopyWith<$Res> {
  factory $DataFormStateCopyWith(
          DataFormState value, $Res Function(DataFormState) then) =
      _$DataFormStateCopyWithImpl<$Res, DataFormState>;
  @useResult
  $Res call(
      {String qrData,
      String description,
      List<String> imagePaths,
      bool isSubmitting,
      bool isSuccess,
      String? errorMessage,
      String? location});
}

/// @nodoc
class _$DataFormStateCopyWithImpl<$Res, $Val extends DataFormState>
    implements $DataFormStateCopyWith<$Res> {
  _$DataFormStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DataFormState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? qrData = null,
    Object? description = null,
    Object? imagePaths = null,
    Object? isSubmitting = null,
    Object? isSuccess = null,
    Object? errorMessage = freezed,
    Object? location = freezed,
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
      imagePaths: null == imagePaths
          ? _value.imagePaths
          : imagePaths // ignore: cast_nullable_to_non_nullable
              as List<String>,
      isSubmitting: null == isSubmitting
          ? _value.isSubmitting
          : isSubmitting // ignore: cast_nullable_to_non_nullable
              as bool,
      isSuccess: null == isSuccess
          ? _value.isSuccess
          : isSuccess // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DataFormStateImplCopyWith<$Res>
    implements $DataFormStateCopyWith<$Res> {
  factory _$$DataFormStateImplCopyWith(
          _$DataFormStateImpl value, $Res Function(_$DataFormStateImpl) then) =
      __$$DataFormStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String qrData,
      String description,
      List<String> imagePaths,
      bool isSubmitting,
      bool isSuccess,
      String? errorMessage,
      String? location});
}

/// @nodoc
class __$$DataFormStateImplCopyWithImpl<$Res>
    extends _$DataFormStateCopyWithImpl<$Res, _$DataFormStateImpl>
    implements _$$DataFormStateImplCopyWith<$Res> {
  __$$DataFormStateImplCopyWithImpl(
      _$DataFormStateImpl _value, $Res Function(_$DataFormStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of DataFormState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? qrData = null,
    Object? description = null,
    Object? imagePaths = null,
    Object? isSubmitting = null,
    Object? isSuccess = null,
    Object? errorMessage = freezed,
    Object? location = freezed,
  }) {
    return _then(_$DataFormStateImpl(
      qrData: null == qrData
          ? _value.qrData
          : qrData // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      imagePaths: null == imagePaths
          ? _value._imagePaths
          : imagePaths // ignore: cast_nullable_to_non_nullable
              as List<String>,
      isSubmitting: null == isSubmitting
          ? _value.isSubmitting
          : isSubmitting // ignore: cast_nullable_to_non_nullable
              as bool,
      isSuccess: null == isSuccess
          ? _value.isSuccess
          : isSuccess // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$DataFormStateImpl implements _DataFormState {
  const _$DataFormStateImpl(
      {required this.qrData,
      required this.description,
      final List<String> imagePaths = const [],
      this.isSubmitting = false,
      this.isSuccess = false,
      this.errorMessage,
      this.location})
      : _imagePaths = imagePaths;

  @override
  final String qrData;
  @override
  final String description;
  final List<String> _imagePaths;
  @override
  @JsonKey()
  List<String> get imagePaths {
    if (_imagePaths is EqualUnmodifiableListView) return _imagePaths;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_imagePaths);
  }

  @override
  @JsonKey()
  final bool isSubmitting;
  @override
  @JsonKey()
  final bool isSuccess;
  @override
  final String? errorMessage;
  @override
  final String? location;

  @override
  String toString() {
    return 'DataFormState(qrData: $qrData, description: $description, imagePaths: $imagePaths, isSubmitting: $isSubmitting, isSuccess: $isSuccess, errorMessage: $errorMessage, location: $location)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DataFormStateImpl &&
            (identical(other.qrData, qrData) || other.qrData == qrData) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality()
                .equals(other._imagePaths, _imagePaths) &&
            (identical(other.isSubmitting, isSubmitting) ||
                other.isSubmitting == isSubmitting) &&
            (identical(other.isSuccess, isSuccess) ||
                other.isSuccess == isSuccess) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.location, location) ||
                other.location == location));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      qrData,
      description,
      const DeepCollectionEquality().hash(_imagePaths),
      isSubmitting,
      isSuccess,
      errorMessage,
      location);

  /// Create a copy of DataFormState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DataFormStateImplCopyWith<_$DataFormStateImpl> get copyWith =>
      __$$DataFormStateImplCopyWithImpl<_$DataFormStateImpl>(this, _$identity);
}

abstract class _DataFormState implements DataFormState {
  const factory _DataFormState(
      {required final String qrData,
      required final String description,
      final List<String> imagePaths,
      final bool isSubmitting,
      final bool isSuccess,
      final String? errorMessage,
      final String? location}) = _$DataFormStateImpl;

  @override
  String get qrData;
  @override
  String get description;
  @override
  List<String> get imagePaths;
  @override
  bool get isSubmitting;
  @override
  bool get isSuccess;
  @override
  String? get errorMessage;
  @override
  String? get location;

  /// Create a copy of DataFormState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DataFormStateImplCopyWith<_$DataFormStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
