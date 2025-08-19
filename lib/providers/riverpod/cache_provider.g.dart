// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cache_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$cacheServiceHash() => r'cb42aa8fc3d415df1a8d5e8a3f36d45b25a0f16b';

/// See also [cacheService].
@ProviderFor(cacheService)
final cacheServiceProvider = AutoDisposeProvider<CacheService>.internal(
  cacheService,
  name: r'cacheServiceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$cacheServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CacheServiceRef = AutoDisposeProviderRef<CacheService>;
String _$cachedDataNotifierHash() =>
    r'5505dcba0a316bb6b403a0f86e92d308492f263e';

/// 캐시된 데이터를 관리하는 provider
///
/// Copied from [CachedDataNotifier].
@ProviderFor(CachedDataNotifier)
final cachedDataNotifierProvider = AutoDisposeAsyncNotifierProvider<
    CachedDataNotifier, Map<String, dynamic>>.internal(
  CachedDataNotifier.new,
  name: r'cachedDataNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$cachedDataNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CachedDataNotifier = AutoDisposeAsyncNotifier<Map<String, dynamic>>;
String _$cachedItemNotifierHash() =>
    r'415cc35e56dd9ae939847e6912a2b4c3467aea4e';

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

abstract class _$CachedItemNotifier
    extends BuildlessAutoDisposeAsyncNotifier<dynamic> {
  late final String key;

  FutureOr<dynamic> build(
    String key,
  );
}

/// 특정 키의 캐시된 데이터를 관리하는 provider
///
/// Copied from [CachedItemNotifier].
@ProviderFor(CachedItemNotifier)
const cachedItemNotifierProvider = CachedItemNotifierFamily();

/// 특정 키의 캐시된 데이터를 관리하는 provider
///
/// Copied from [CachedItemNotifier].
class CachedItemNotifierFamily extends Family<AsyncValue<dynamic>> {
  /// 특정 키의 캐시된 데이터를 관리하는 provider
  ///
  /// Copied from [CachedItemNotifier].
  const CachedItemNotifierFamily();

  /// 특정 키의 캐시된 데이터를 관리하는 provider
  ///
  /// Copied from [CachedItemNotifier].
  CachedItemNotifierProvider call(
    String key,
  ) {
    return CachedItemNotifierProvider(
      key,
    );
  }

  @override
  CachedItemNotifierProvider getProviderOverride(
    covariant CachedItemNotifierProvider provider,
  ) {
    return call(
      provider.key,
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
  String? get name => r'cachedItemNotifierProvider';
}

/// 특정 키의 캐시된 데이터를 관리하는 provider
///
/// Copied from [CachedItemNotifier].
class CachedItemNotifierProvider
    extends AutoDisposeAsyncNotifierProviderImpl<CachedItemNotifier, dynamic> {
  /// 특정 키의 캐시된 데이터를 관리하는 provider
  ///
  /// Copied from [CachedItemNotifier].
  CachedItemNotifierProvider(
    String key,
  ) : this._internal(
          () => CachedItemNotifier()..key = key,
          from: cachedItemNotifierProvider,
          name: r'cachedItemNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$cachedItemNotifierHash,
          dependencies: CachedItemNotifierFamily._dependencies,
          allTransitiveDependencies:
              CachedItemNotifierFamily._allTransitiveDependencies,
          key: key,
        );

  CachedItemNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.key,
  }) : super.internal();

  final String key;

  @override
  FutureOr<dynamic> runNotifierBuild(
    covariant CachedItemNotifier notifier,
  ) {
    return notifier.build(
      key,
    );
  }

  @override
  Override overrideWith(CachedItemNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: CachedItemNotifierProvider._internal(
        () => create()..key = key,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        key: key,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<CachedItemNotifier, dynamic>
      createElement() {
    return _CachedItemNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CachedItemNotifierProvider && other.key == key;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, key.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin CachedItemNotifierRef on AutoDisposeAsyncNotifierProviderRef<dynamic> {
  /// The parameter `key` of this provider.
  String get key;
}

class _CachedItemNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<CachedItemNotifier, dynamic>
    with CachedItemNotifierRef {
  _CachedItemNotifierProviderElement(super.provider);

  @override
  String get key => (origin as CachedItemNotifierProvider).key;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
