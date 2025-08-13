import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  // .env 파일에서 환경변수 로드
  static String get supabaseUrl {
    return dotenv.env['SUPABASE_URL'] ?? 'https://your-project-ref.supabase.co';
  }
  
  static String get supabaseAnonKey {
    return dotenv.env['SUPABASE_ANON_KEY'] ?? 'your-anon-key-here';
  }
  
  // 환경변수 로드 확인
  static bool get isConfigured {
    final url = dotenv.env['SUPABASE_URL'];
    final key = dotenv.env['SUPABASE_ANON_KEY'];
    return url != null && key != null && 
           url.isNotEmpty && key.isNotEmpty &&
           !url.contains('dummy') && 
           !key.contains('dummy');
  }
}
