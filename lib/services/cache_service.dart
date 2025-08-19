import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 캐싱 서비스 - 로컬 저장소를 활용한 데이터 캐싱
class CacheService {
  static const String _cachePrefix = 'cache_';
  static const Duration _defaultExpiry = Duration(hours: 1);
  
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  /// 데이터를 캐시에 저장
  Future<void> setData(String key, dynamic data, {Duration? expiry}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'expiry': (expiry ?? _defaultExpiry).inMilliseconds,
      };
      
      await prefs.setString('$_cachePrefix$key', jsonEncode(cacheData));
    } catch (e) {
      // 캐시 저장 실패 시 무시
    }
  }

  /// 캐시에서 데이터 가져오기
  Future<T?> getData<T>(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedString = prefs.getString('$_cachePrefix$key');
      
      if (cachedString == null) return null;
      
      final cacheData = jsonDecode(cachedString) as Map<String, dynamic>;
      final timestamp = cacheData['timestamp'] as int;
      final expiry = cacheData['expiry'] as int;
      
      // 만료 시간 확인
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - timestamp > expiry) {
        // 만료된 데이터 삭제
        await prefs.remove('$_cachePrefix$key');
        return null;
      }
      
      return cacheData['data'] as T;
    } catch (e) {
      // 캐시 읽기 실패 시 null 반환
      return null;
    }
  }

  /// 특정 키의 캐시 삭제
  Future<void> removeData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_cachePrefix$key');
    } catch (e) {
      // 캐시 삭제 실패 시 무시
    }
  }

  /// 모든 캐시 삭제
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (final key in keys) {
        if (key.startsWith(_cachePrefix)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      // 캐시 삭제 실패 시 무시
    }
  }

  /// 캐시 크기 확인
  Future<int> getCacheSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      int size = 0;
      for (final key in keys) {
        if (key.startsWith(_cachePrefix)) {
          final value = prefs.getString(key);
          if (value != null) {
            size += value.length;
          }
        }
      }
      
      return size;
    } catch (e) {
      return 0;
    }
  }

  /// 만료된 캐시 정리
  Future<void> cleanupExpired() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final now = DateTime.now().millisecondsSinceEpoch;
      
      for (final key in keys) {
        if (key.startsWith(_cachePrefix)) {
          final cachedString = prefs.getString(key);
          if (cachedString != null) {
            try {
              final cacheData = jsonDecode(cachedString) as Map<String, dynamic>;
              final timestamp = cacheData['timestamp'] as int;
              final expiry = cacheData['expiry'] as int;
              
              if (now - timestamp > expiry) {
                await prefs.remove(key);
              }
            } catch (e) {
              // 잘못된 캐시 데이터 삭제
              await prefs.remove(key);
            }
          }
        }
      }
    } catch (e) {
      // 정리 실패 시 무시
    }
  }
}
