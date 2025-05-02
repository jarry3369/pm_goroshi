// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$reportDataNotifierHash() =>
    r'2afb9734ee3bcfe3e716b466f04775e43fa7032c';

/// See also [ReportDataNotifier].
@ProviderFor(ReportDataNotifier)
final reportDataNotifierProvider = AutoDisposeAsyncNotifierProvider<
    ReportDataNotifier, List<ReportData>>.internal(
  ReportDataNotifier.new,
  name: r'reportDataNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$reportDataNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ReportDataNotifier = AutoDisposeAsyncNotifier<List<ReportData>>;
String _$selectedReportProviderHash() =>
    r'1aff8d742c942cf7980d16f5ae1dcd85457eadd2';

/// See also [SelectedReportProvider].
@ProviderFor(SelectedReportProvider)
final selectedReportProviderProvider =
    AutoDisposeNotifierProvider<SelectedReportProvider, String?>.internal(
  SelectedReportProvider.new,
  name: r'selectedReportProviderProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedReportProviderHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedReportProvider = AutoDisposeNotifier<String?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
