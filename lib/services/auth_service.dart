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
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
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
  Future<UserProfile?> getUserProfile() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
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

  // 이메일 확인 상태 체크
  bool get isEmailConfirmed => currentUser?.emailConfirmedAt != null;

  // 비밀번호 재설정 이메일 발송
  Future<void> resetPassword({required String email}) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }
}
