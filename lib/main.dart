import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_screen.dart';
import 'providers/riverpod/user_provider.dart';
import 'providers/riverpod/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);
    final lightTheme = ref.watch(lightThemeProvider);
    final darkTheme = ref.watch(darkThemeProvider);

    return MaterialApp(
      title: 'LikeGame',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode.value ?? ThemeMode.light,
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStateStream = ref.watch(authStateStreamProvider);

    return authStateStream.when(
      data: (authState) {
        final session = authState.session;
        
        if (session != null) {
          // 로그인 시 프로필 로드
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await ref.read(userNotifierProvider.notifier).loadUserProfile();
          });
          return const MainScreen();
        } else {
          // 로그아웃 시 프로필 초기화
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(userNotifierProvider.notifier).clearProfile();
          });
          return const LoginScreen();
        }
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text('인증 오류: $error'),
        ),
      ),
    );
  }
}