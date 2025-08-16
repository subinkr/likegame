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
  bool get isLoggedIn => _userProfile != null && _authService.currentUser != null;
  String? get deletedAccountMessage => _deletedAccountMessage;

  // 사용자 프로필 로드
  Future<void> loadUserProfile() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final profile = await _authService.getUserProfile();
      _userProfile = profile;
      _deletedAccountMessage = null; // 탈퇴 메시지 초기화
    } catch (e) {
      print('UserProvider - 프로필 로드 실패: $e');
      _userProfile = null;
      
      // 탈퇴한 계정인지 확인
      if (e.toString().contains('탈퇴한 계정입니다')) {
        _deletedAccountMessage = '탈퇴한 계정입니다.';
        // 자동 로그아웃 처리
        await _authService.signOut();
      } else {
        _deletedAccountMessage = null;
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
