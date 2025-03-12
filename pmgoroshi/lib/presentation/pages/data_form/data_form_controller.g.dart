// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_form_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$dataFormControllerHash() =>
    r'e4b8da1018523aebe0788fc3e746485c1164c973';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$DataFormController
    extends BuildlessAutoDisposeNotifier<DataFormState> {
  late final String initialQrData;

  DataFormState build(
    String initialQrData,
  );
}

/// See also [DataFormController].
@ProviderFor(DataFormController)
const dataFormControllerProvider = DataFormControllerFamily();

/// See also [DataFormController].
class DataFormControllerFamily extends Family<DataFormState> {
  /// See also [DataFormController].
  const DataFormControllerFamily();

  /// See also [DataFormController].
  DataFormControllerProvider call(
    String initialQrData,
  ) {
    return DataFormControllerProvider(
      initialQrData,
    );
  }

  @override
  DataFormControllerProvider getProviderOverride(
    covariant DataFormControllerProvider provider,
  ) {
    return call(
      provider.initialQrData,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'dataFormControllerProvider';
}

/// See also [DataFormController].
class DataFormControllerProvider
    extends AutoDisposeNotifierProviderImpl<DataFormController, DataFormState> {
  /// See also [DataFormController].
  DataFormControllerProvider(
    String initialQrData,
  ) : this._internal(
          () => DataFormController()..initialQrData = initialQrData,
          from: dataFormControllerProvider,
          name: r'dataFormControllerProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$dataFormControllerHash,
          dependencies: DataFormControllerFamily._dependencies,
          allTransitiveDependencies:
              DataFormControllerFamily._allTransitiveDependencies,
          initialQrData: initialQrData,
        );

  DataFormControllerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.initialQrData,
  }) : super.internal();

  final String initialQrData;

  @override
  DataFormState runNotifierBuild(
    covariant DataFormController notifier,
  ) {
    return notifier.build(
      initialQrData,
    );
  }

  @override
  Override overrideWith(DataFormController Function() create) {
    return ProviderOverride(
      origin: this,
      override: DataFormControllerProvider._internal(
        () => create()..initialQrData = initialQrData,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        initialQrData: initialQrData,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<DataFormController, DataFormState>
      createElement() {
    return _DataFormControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DataFormControllerProvider &&
        other.initialQrData == initialQrData;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, initialQrData.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DataFormControllerRef on AutoDisposeNotifierProviderRef<DataFormState> {
  /// The parameter `initialQrData` of this provider.
  String get initialQrData;
}

class _DataFormControllerProviderElement
    extends AutoDisposeNotifierProviderElement<DataFormController,
        DataFormState> with DataFormControllerRef {
  _DataFormControllerProviderElement(super.provider);

  @override
  String get initialQrData =>
      (origin as DataFormControllerProvider).initialQrData;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
