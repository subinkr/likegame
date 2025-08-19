import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';

part 'user_provider.g.dart';

@riverpod
class UserNotifier extends _$UserNotifier {
  late final AuthService _authService;

  @override
  FutureOr<UserProfile?> build() async {
    _authService = AuthService();
    return await _loadUserProfile();
  }

  Future<UserProfile?> _loadUserProfile() async {
    try {
      final profile = await _authService.getUserProfile();
      return profile;
    } catch (e) {
      // 탈퇴한 계정인지 확인
      if (e.toString().contains('탈퇴한 계정입니다')) {
        // 자동 로그아웃 처리
        await _authService.signOut();
      }
      return null;
    }
  }

  Future<void> loadUserProfile() async {
    state = const AsyncValue.loading();
    try {
      final profile = await _loadUserProfile();
      state = AsyncValue.data(profile);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateProfile({required String nickname}) async {
    if (state.value == null) return;

    try {
      await _authService.updateProfile(nickname: nickname);
      await loadUserProfile(); // 프로필 다시 로드
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateUserProfile({
    required String userId,
    required String nickname,
  }) async {
    try {
      await _authService.updateUserProfile(
        userId: userId,
        nickname: nickname,
      );
      await loadUserProfile(); // 프로필 다시 로드
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  void clearProfile() {
    state = const AsyncValue.data(null);
  }

  String? get currentUserId => _authService.currentUser?.id;
  bool get isLoggedIn => state.value != null && _authService.currentUser != null;
}

@riverpod
AuthService authService(AuthServiceRef ref) {
  return AuthService();
}

@riverpod
Stream<AuthState> authStateStream(AuthStateStreamRef ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateStream;
}
