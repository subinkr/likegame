import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'network_provider.g.dart';

@riverpod
class NetworkNotifier extends _$NetworkNotifier {
  late final Connectivity _connectivity;
  StreamSubscription<ConnectivityResult>? _subscription;

  @override
  FutureOr<NetworkStatus> build() async {
    _connectivity = Connectivity();
    
    // 초기 연결 상태 확인
    final initialResult = await _connectivity.checkConnectivity();
    final initialStatus = _mapConnectivityResult(initialResult);
    
    // 연결 상태 변화 감지
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      final status = _mapConnectivityResult(result);
      state = AsyncValue.data(status);
    });
    
    return initialStatus;
  }

  NetworkStatus _mapConnectivityResult(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return NetworkStatus.connected;
      case ConnectivityResult.mobile:
        return NetworkStatus.connected;
      case ConnectivityResult.ethernet:
        return NetworkStatus.connected;
      case ConnectivityResult.vpn:
        return NetworkStatus.connected;
      case ConnectivityResult.bluetooth:
        return NetworkStatus.connected;
      case ConnectivityResult.other:
        return NetworkStatus.connected;
      case ConnectivityResult.none:
        return NetworkStatus.disconnected;
    }
  }

  void dispose() {
    _subscription?.cancel();
  }

  /// 현재 네트워크 상태 확인
  bool get isConnected => state.value == NetworkStatus.connected;
  
  /// 오프라인 모드인지 확인
  bool get isOffline => state.value == NetworkStatus.disconnected;
}

/// 네트워크 상태 열거형
enum NetworkStatus {
  connected,
  disconnected,
}

/// 오프라인 모드 관리 provider
@riverpod
class OfflineModeNotifier extends _$OfflineModeNotifier {
  @override
  FutureOr<bool> build() async {
    // 기본적으로 온라인 모드
    return false;
  }

  /// 오프라인 모드 토글
  void toggleOfflineMode() {
    final currentMode = state.value ?? false;
    state = AsyncValue.data(!currentMode);
  }

  /// 오프라인 모드 설정
  void setOfflineMode(bool isOffline) {
    state = AsyncValue.data(isOffline);
  }

  /// 오프라인 모드인지 확인
  bool get isOfflineMode => state.value ?? false;
}
