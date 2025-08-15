import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'config/supabase_config.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_screen.dart';
import 'services/auth_service.dart';
import 'providers/user_provider.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'LikeGame',
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: '/',
            routes: {
              '/': (context) => const AuthWrapper(),
              '/login': (context) => const LoginScreen(),
            },
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authService.authStateStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final authState = snapshot.data;
        final session = authState?.session;
        
        if (session != null) {
          // 로그인 시 프로필 로드 및 검증
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final userProvider = context.read<UserProvider>();
            await userProvider.loadUserProfile();
            
            // 탈퇴한 계정인 경우 로그아웃 처리
            if (userProvider.deletedAccountMessage != null) {
              print('AuthWrapper - 탈퇴한 계정 감지, 로그아웃 처리');
              await _authService.signOut();
            }
          });
          return const MainScreen();
        } else {
          // 로그아웃 시 프로필 초기화
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<UserProvider>().clearProfile();
          });
          return const LoginScreen();
        }
      },
    );
  }
}