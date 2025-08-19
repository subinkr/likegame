// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$networkNotifierHash() => r'ac6cd281f9a8d53c8dd0b5ff89852ec3b96ff666';

/// See also [NetworkNotifier].
@ProviderFor(NetworkNotifier)
final networkNotifierProvider =
    AutoDisposeAsyncNotifierProvider<NetworkNotifier, NetworkStatus>.internal(
  NetworkNotifier.new,
  name: r'networkNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$networkNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$NetworkNotifier = AutoDisposeAsyncNotifier<NetworkStatus>;
String _$offlineModeNotifierHash() =>
    r'e889b0827d315814e0546b72316b4220c1b2a960';

/// 오프라인 모드 관리 provider
///
/// Copied from [OfflineModeNotifier].
@ProviderFor(OfflineModeNotifier)
final offlineModeNotifierProvider =
    AutoDisposeAsyncNotifierProvider<OfflineModeNotifier, bool>.internal(
  OfflineModeNotifier.new,
  name: r'offlineModeNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$offlineModeNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$OfflineModeNotifier = AutoDisposeAsyncNotifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
