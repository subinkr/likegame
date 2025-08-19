import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../config/supabase_config.dart';
import '../utils/error_handler.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;
  
  Stream<AuthState> get authStateStream => _supabase.auth.onAuthStateChange;

  // 회원가입
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    try {
      if (!SupabaseConfig.isConfigured) {
        throw const AppError(
          type: AppErrorType.validation,
          message: 'Supabase 설정이 완료되지 않았습니다. 설정을 확인해주세요.',
        );
      }
      
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      
      return response;
    } catch (e) {
      throw ErrorHandler.handleSupabaseError(e);
    }
  }

  // 이메일로 계정 상태 확인 (로그인 전)
  Future<bool> checkAccountStatus(String email) async {
    try {
      final result = await _supabase
          .from('profiles')
          .select('is_deleted')
          .eq('email', email)
          .maybeSingle();
      
      if (result != null && result['is_deleted'] == true) {
        return true; // 탈퇴한 계정
      }
      return false; // 정상 계정 또는 계정 없음
    } catch (e) {
      // 조회 실패 시 false 반환 (정상 계정으로 처리)
      return false;
    }
  }

  // 로그인
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // 로그인 시도 전에 탈퇴한 계정인지 먼저 확인
      final isDeleted = await checkAccountStatus(email);
      if (isDeleted) {
        throw Exception('탈퇴한 계정입니다.');
      }
      
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      // 로그인 성공 후 즉시 탈퇴한 계정인지 확인 (이중 체크)
      try {
        final user = response.user;
        if (user != null) {
          // is_deleted만 확인하는 간단한 쿼리
          final result = await _supabase
              .from('profiles')
              .select('is_deleted')
              .eq('id', user.id)
              .single();
          
          if (result['is_deleted'] == true) {
            // 탈퇴한 계정이면 즉시 로그아웃
            await _supabase.auth.signOut();
            throw Exception('탈퇴한 계정입니다.');
          }
        }
      } catch (e) {
        // 프로필 조회 실패 시에도 로그아웃
        await _supabase.auth.signOut();
        if (e.toString().contains('탈퇴한 계정입니다')) {
          rethrow;
        }
        throw Exception('계정 정보를 확인할 수 없습니다.');
      }
      
      return response;
    } catch (e) {
      // 탈퇴한 계정 에러는 그대로 전달
      if (e.toString().contains('탈퇴한 계정입니다')) {
        rethrow;
      }
      throw ErrorHandler.handleSupabaseError(e);
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // 사용자 프로필 가져오기
  Future<UserProfile?> getUserProfile([String? userId]) async {
    try {
      final user = userId != null ? userId : currentUser?.id;
      if (user == null) return null;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', user)
          .single();

      final profile = UserProfile.fromJson(response);
      
      // 탈퇴한 계정인지 확인
      if (profile.isDeleted) {
        throw Exception('탈퇴한 계정입니다.');
      }
      
      return profile;
    } catch (e) {
      // 406 오류나 다른 오류 시 로그아웃 처리
      if (e.toString().contains('406') || e.toString().contains('Not Acceptable')) {
        await _supabase.auth.signOut();
        throw Exception('탈퇴한 계정입니다.');
      }
      rethrow;
    }
  }

  // 프로필 업데이트
  Future<void> updateProfile({
    required String nickname,
  }) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not logged in');

      await _supabase
          .from('profiles')
          .update({
            'nickname': nickname,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);
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
      await _supabase
          .from('profiles')
          .update({
            'nickname': nickname,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
    } catch (e) {
      rethrow;
    }
  }

  // 비밀번호 변경
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(
          password: newPassword,
        ),
      );
    } on AuthException catch (e) {
      switch (e.message) {
        case 'Invalid login credentials':
          throw Exception('현재 비밀번호가 올바르지 않습니다.');
        case 'Password should be at least 6 characters':
          throw Exception('새 비밀번호는 최소 6자 이상이어야 합니다.');
        default:
          throw Exception('비밀번호 변경 실패: ${e.message}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // 계정 탈퇴 (클라이언트 직접 처리)
  Future<void> deleteAccount(String password) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('로그인이 필요합니다.');

      // 1. 비밀번호 확인 (재인증)
      await _supabase.auth.signInWithPassword(
        email: user.email ?? '',
        password: password,
      );

      // 2. 사용자 데이터 삭제
      await _deleteUserData(user.id);

      // 3. is_deleted = true로 설정 (계정 완전 삭제 없이)
      try {
        await _supabase
            .from('profiles')
            .update({
              'is_deleted': true,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', user.id);
      } catch (e) {
        // 계정 탈퇴 처리 실패
      }

      // 4. 로그아웃
      await _supabase.auth.signOut();

    } on AuthException catch (e) {
      switch (e.message) {
        case 'Invalid login credentials':
          throw Exception('비밀번호가 올바르지 않습니다.');
        case 'User not found':
          throw Exception('사용자를 찾을 수 없습니다.');
        case 'Email not confirmed':
          throw Exception('이메일 인증이 필요합니다.');
        default:
          throw Exception('계정 탈퇴 실패: ${e.message}');
      }
    } catch (e) {
      if (e.toString().contains('network') || e.toString().contains('timeout')) {
        throw Exception('네트워크 오류가 발생했습니다. 다시 시도해주세요.');
      }
      throw Exception('계정 탈퇴 중 오류가 발생했습니다: ${e.toString()}');
    }
  }



  // 사용자 데이터 삭제 (새로운 방법)
  Future<void> _deleteUserData(String userId) async {
    try {
      // 1. 사용자 마일스톤 삭제
      try {
        await _supabase.from('user_milestones').delete().eq('user_id', userId);
      } catch (e) {
        // 마일스톤 삭제 실패
      }

      // 2. 스탯 우선순위 삭제
      try {
        await _supabase.from('user_stat_priorities').delete().eq('user_id', userId);
      } catch (e) {
        // 스탯 우선순위 삭제 실패
      }

      // 3. 스킬 삭제
      try {
        await _supabase.from('skills').delete().eq('user_id', userId);
      } catch (e) {
        // 스킬 삭제 실패
      }

      // 4. 퀘스트 삭제
      try {
        await _supabase.from('quests').delete().eq('user_id', userId);
      } catch (e) {
        // 퀘스트 삭제 실패
      }

      // 5. 프로필은 삭제하지 않음 (초기화로 대체)
    } catch (e) {
      // 사용자 데이터 삭제 중 오류
      // 데이터 삭제 실패해도 계정 탈퇴는 계속 진행
    }
  }

  // 이메일 확인 상태 체크
  bool get isEmailConfirmed => currentUser?.emailConfirmedAt != null;


}
