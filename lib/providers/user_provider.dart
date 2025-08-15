import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/auth_service.dart';

class UserProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserProfile? _userProfile;
  bool _isLoading = false;

  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _authService.currentUser != null;

  // 사용자 프로필 로드
  Future<void> loadUserProfile() async {
    if (!isLoggedIn) {
      return;
    }
    
    _isLoading = true;
    notifyListeners();

    try {
      final profile = await _authService.getUserProfile();
      _userProfile = profile;
    } catch (e) {
      // 프로필 로드 실패 시 무시
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 프로필 업데이트
  Future<void> updateProfile({required String nickname}) async {
    if (!isLoggedIn) return;

    try {
      await _authService.updateProfile(nickname: nickname);
      await loadUserProfile(); // 프로필 다시 로드
    } catch (e) {
      rethrow;
    }
  }

  // 사용자 프로필 업데이트 (userId 지정)
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
      rethrow;
    }
  }

  // 로그아웃 시 프로필 초기화
  void clearProfile() {
    _userProfile = null;
    _isLoading = false;
    notifyListeners();
  }

  // 현재 사용자 ID 가져오기
  String? get currentUserId => _authService.currentUser?.id;
}
