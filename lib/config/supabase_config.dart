class SupabaseConfig {
  // Supabase 설정 (anon key는 안전함)
  static const String supabaseUrl = 'https://lzaijefnntivfcnhrbks.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx6YWlqZWZubnRpdmZjbmhyYmtzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUwNDU3ODksImV4cCI6MjA3MDYyMTc4OX0.t52NWKpBHkLXY5Z6CdXQOJD6aG1mS1Yi76N3fv3Xp90';

  // 설정 확인
  static bool get isConfigured {
    return supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  }
}
