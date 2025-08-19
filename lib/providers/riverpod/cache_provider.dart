import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../services/cache_service.dart';

part 'cache_provider.g.dart';

@riverpod
CacheService cacheService(CacheServiceRef ref) {
  return CacheService();
}

/// 캐시된 데이터를 관리하는 provider
@riverpod
class CachedDataNotifier extends _$CachedDataNotifier {
  late final CacheService _cacheService;

  @override
  FutureOr<Map<String, dynamic>> build() async {
    _cacheService = ref.read(cacheServiceProvider);
    return {};
  }

  /// 데이터를 캐시에 저장
  Future<void> setData(String key, dynamic data, {Duration? expiry}) async {
    await _cacheService.setData(key, data, expiry: expiry);
    // 상태 업데이트
    final currentState = state.value ?? {};
    final newState = Map<String, dynamic>.from(currentState);
    newState[key] = data;
    state = AsyncValue.data(newState);
  }

  /// 캐시에서 데이터 가져오기
  Future<T?> getData<T>(String key) async {
    return await _cacheService.getData<T>(key);
  }

  /// 특정 키의 캐시 삭제
  Future<void> removeData(String key) async {
    await _cacheService.removeData(key);
    // 상태 업데이트
    final currentState = state.value ?? {};
    final newState = Map<String, dynamic>.from(currentState);
    newState.remove(key);
    state = AsyncValue.data(newState);
  }

  /// 모든 캐시 삭제
  Future<void> clearAll() async {
    await _cacheService.clearAll();
    state = const AsyncValue.data({});
  }

  /// 캐시 크기 확인
  Future<int> getCacheSize() async {
    return await _cacheService.getCacheSize();
  }

  /// 만료된 캐시 정리
  Future<void> cleanupExpired() async {
    await _cacheService.cleanupExpired();
    // 정리 후 상태 새로고침
    ref.invalidateSelf();
  }
}

/// 특정 키의 캐시된 데이터를 관리하는 provider
@riverpod
class CachedItemNotifier extends _$CachedItemNotifier {
  late final CacheService _cacheService;

  @override
  FutureOr<dynamic> build(String key) async {
    _cacheService = ref.read(cacheServiceProvider);
    return await _cacheService.getData(key);
  }

  /// 데이터 업데이트
  Future<void> updateData(dynamic data, {Duration? expiry}) async {
    await _cacheService.setData(key, data, expiry: expiry);
    state = AsyncValue.data(data);
  }

  /// 데이터 삭제
  Future<void> removeData() async {
    await _cacheService.removeData(key);
    state = const AsyncValue.data(null);
  }
}
