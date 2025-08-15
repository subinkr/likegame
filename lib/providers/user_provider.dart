import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/auth_service.dart';

class UserProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _deletedAccountMessage;

  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _authService.currentUser != null;
  String? get deletedAccountMessage => _deletedAccountMessage;

  // 사용자 프로필 로드
  Future<void> loadUserProfile() async {
    try {
      final profile = await _authService.getUserProfile();
      if (profile != null) {
        _userProfile = profile;
        _isLoading = true;
        notifyListeners();
      }
    } catch (e) {
      print('UserProvider - 프로필 로드 실패');
      if (e.toString().contains('탈퇴한 계정입니다')) {
        print('UserProvider - 탈퇴한 계정 감지');
        _userProfile = null;
        _deletedAccountMessage = '탈퇴한 계정입니다.';
        notifyListeners();
        rethrow;
      }
      // 406 오류 시 프로필 초기화
      if (e.toString().contains('406') || e.toString().contains('Not Acceptable')) {
        print('UserProvider - 406 오류 감지, 프로필 초기화');
        _userProfile = null;
      }
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
    _deletedAccountMessage = null;
    notifyListeners();
  }

  // 현재 사용자 ID 가져오기
  String? get currentUserId => _authService.currentUser?.id;
}
