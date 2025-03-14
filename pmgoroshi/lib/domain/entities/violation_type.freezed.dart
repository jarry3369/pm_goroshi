// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'violation_type.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ViolationType _$ViolationTypeFromJson(Map<String, dynamic> json) {
  return _ViolationType.fromJson(json);
}

/// @nodoc
mixin _$ViolationType {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;

  /// Serializes this ViolationType to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ViolationType
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ViolationTypeCopyWith<ViolationType> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ViolationTypeCopyWith<$Res> {
  factory $ViolationTypeCopyWith(
          ViolationType value, $Res Function(ViolationType) then) =
      _$ViolationTypeCopyWithImpl<$Res, ViolationType>;
  @useResult
  $Res call({String id, String name});
}

/// @nodoc
class _$ViolationTypeCopyWithImpl<$Res, $Val extends ViolationType>
    implements $ViolationTypeCopyWith<$Res> {
  _$ViolationTypeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ViolationType
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ViolationTypeImplCopyWith<$Res>
    implements $ViolationTypeCopyWith<$Res> {
  factory _$$ViolationTypeImplCopyWith(
          _$ViolationTypeImpl value, $Res Function(_$ViolationTypeImpl) then) =
      __$$ViolationTypeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name});
}

/// @nodoc
class __$$ViolationTypeImplCopyWithImpl<$Res>
    extends _$ViolationTypeCopyWithImpl<$Res, _$ViolationTypeImpl>
    implements _$$ViolationTypeImplCopyWith<$Res> {
  __$$ViolationTypeImplCopyWithImpl(
      _$ViolationTypeImpl _value, $Res Function(_$ViolationTypeImpl) _then)
      : super(_value, _then);

  /// Create a copy of ViolationType
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
  }) {
    return _then(_$ViolationTypeImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ViolationTypeImpl implements _ViolationType {
  const _$ViolationTypeImpl({required this.id, required this.name});

  factory _$ViolationTypeImpl.fromJson(Map<String, dynamic> json) =>
      _$$ViolationTypeImplFromJson(json);

  @override
  final String id;
  @override
  final String name;

  @override
  String toString() {
    return 'ViolationType(id: $id, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ViolationTypeImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name);

  /// Create a copy of ViolationType
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ViolationTypeImplCopyWith<_$ViolationTypeImpl> get copyWith =>
      __$$ViolationTypeImplCopyWithImpl<_$ViolationTypeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ViolationTypeImplToJson(
      this,
    );
  }
}

abstract class _ViolationType implements ViolationType {
  const factory _ViolationType(
      {required final String id,
      required final String name}) = _$ViolationTypeImpl;

  factory _ViolationType.fromJson(Map<String, dynamic> json) =
      _$ViolationTypeImpl.fromJson;

  @override
  String get id;
  @override
  String get name;

  /// Create a copy of ViolationType
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ViolationTypeImplCopyWith<_$ViolationTypeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
