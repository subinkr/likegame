import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../config/supabase_config.dart';

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
      // Supabase 연결 상태 확인

      
      if (!SupabaseConfig.isConfigured) {
        throw Exception('Supabase 설정이 완료되지 않았습니다. .env 파일에서 SUPABASE_URL과 SUPABASE_ANON_KEY를 설정해주세요.');
      }
      
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      
      // 프로필은 트리거에서 자동으로 생성됨
      // 추가 작업이 필요하면 여기에 작성
      
      return response;
    } on AuthException catch (e) {
      // Supabase 인증 오류 처리
      switch (e.message) {
        case 'User already registered':
          throw Exception('이미 등록된 이메일입니다.');
        case 'Password should be at least 6 characters':
          throw Exception('비밀번호는 최소 6자 이상이어야 합니다.');
        case 'Invalid email':
          throw Exception('올바른 이메일 형식을 입력해주세요.');
        default:
          if (e.message.contains('404') || e.message.contains('empty response')) {
            throw Exception('Supabase 서버에 연결할 수 없습니다. 설정을 확인해주세요.');
          }
          throw Exception('회원가입 오류: ${e.message}');
      }
    } catch (e) {
      if (e.toString().contains('404') || e.toString().contains('empty response')) {
        throw Exception('Supabase 서버 연결 오류: 설정 파일의 URL과 API 키를 확인해주세요.');
      }
      rethrow;
    }
  }

  // 로그인
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      // Supabase 인증 오류 처리
      switch (e.message) {
        case 'Invalid login credentials':
          throw Exception('이메일 또는 비밀번호가 올바르지 않습니다.');
        case 'Email not confirmed':
          throw Exception('이메일 인증이 필요합니다. 이메일을 확인해주세요.');
        case 'Too many requests':
          throw Exception('너무 많은 로그인 시도가 있었습니다. 잠시 후 다시 시도해주세요.');
        case 'User not found':
          throw Exception('등록되지 않은 이메일입니다. 회원가입을 먼저 해주세요.');
        case 'Invalid email':
          throw Exception('올바른 이메일 형식을 입력해주세요.');
        case 'Password should be at least 6 characters':
          throw Exception('비밀번호는 최소 6자 이상이어야 합니다.');
        default:
          if (e.message.contains('404') || e.message.contains('empty response')) {
            throw Exception('서버에 연결할 수 없습니다. 인터넷 연결을 확인해주세요.');
          }
          throw Exception('로그인 오류: ${e.message}');
      }
    } catch (e) {
      if (e.toString().contains('404') || e.toString().contains('empty response')) {
        throw Exception('서버 연결 오류: 설정을 확인해주세요.');
      }
      if (e.toString().contains('timeout')) {
        throw Exception('로그인 시간이 초과되었습니다. 다시 시도해주세요.');
      }
      if (e.toString().contains('network')) {
        throw Exception('네트워크 오류가 발생했습니다. 인터넷 연결을 확인해주세요.');
      }
      rethrow;
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

      return UserProfile.fromJson(response);
    } catch (e) {
      return null;
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

  // 계정 삭제
  Future<void> deleteAccount(String password) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('로그인이 필요합니다.');

      // 먼저 현재 비밀번호로 재인증
      await _supabase.auth.signInWithPassword(
        email: user.email ?? '',
        password: password,
      );

      // 사용자 데이터 삭제 (프로필, 마일스톤, 스킬, 퀘스트 등)
      await _deleteUserData(user.id);

      // 계정 비활성화 (이메일을 무효한 주소로 변경)
      await _supabase.auth.updateUser(
        UserAttributes(
          email: 'deleted_${user.id}_${DateTime.now().millisecondsSinceEpoch}@deleted.com',
        ),
      );

      // 로그아웃
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
          throw Exception('계정 삭제 실패: ${e.message}');
      }
    } catch (e) {
      if (e.toString().contains('network') || e.toString().contains('timeout')) {
        throw Exception('네트워크 오류가 발생했습니다. 다시 시도해주세요.');
      }
      rethrow;
    }
  }

  // 사용자 데이터 삭제
  Future<void> _deleteUserData(String userId) async {
    try {
      // 사용자의 모든 데이터 삭제
      await _supabase.from('user_milestones').delete().eq('user_id', userId);
      await _supabase.from('user_stat_priorities').delete().eq('user_id', userId);
      await _supabase.from('skills').delete().eq('user_id', userId);
      await _supabase.from('quests').delete().eq('user_id', userId);
      await _supabase.from('profiles').delete().eq('id', userId);
    } catch (e) {
      // 데이터 삭제 실패해도 계정 삭제는 계속 진행
      print('사용자 데이터 삭제 중 오류: $e');
    }
  }

  // 이메일 확인 상태 체크
  bool get isEmailConfirmed => currentUser?.emailConfirmedAt != null;


}
