import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
// 통합된 ShareService import
import '../services/share_service.dart';


import '../services/auth_service.dart';
import '../services/stat_service.dart';
import '../services/quest_service.dart';
import '../services/skill_service.dart';
import '../utils/text_utils.dart';
import '../providers/user_provider.dart';
import '../providers/theme_provider.dart';
import '../models/models.dart';
import 'privacy_policy_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final StatService _statService = StatService();
  final QuestService _questService = QuestService();
  final SkillService _skillService = SkillService();
  final GlobalKey _profileImageKey = GlobalKey();
  
  List<SkillProgress> _skills = [];
  int _completedQuests = 0;
  int _totalSkillsCount = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    // 프로필 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadUserProfile();
      _loadStats();
    });
  }

  Future<void> _loadStats() async {
    try {
      final userId = context.read<UserProvider>().currentUserId;
      if (userId == null) return;

      final stats = await _statService.getUserSkillsProgress(userId);
      final skills = await _skillService.getUserSkills(userId);
      final quests = await _questService.getUserQuests(userId);
      final completedQuests = quests.where((quest) => quest.isCompleted).length;

      if (mounted) {
        setState(() {
          _skills = stats;
          _totalSkillsCount = skills.length;
          _completedQuests = completedQuests;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  Future<void> _shareProfileAsImage() async {
    try {
      // 로딩 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      if (kIsWeb) {
        // 웹 환경에서는 Canvas를 사용한 이미지 생성
        try {
          // 위젯을 이미지로 변환
          final RenderRepaintBoundary boundary = _profileImageKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
          final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
          final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
          
          if (byteData == null) {
            if (mounted) {
              Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('이미지 생성에 실패했습니다'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }

          // 로딩 다이얼로그 닫기
          if (mounted) {
            Navigator.of(context).pop();
          }

          final bytes = byteData.buffer.asUint8List();
          final filename = 'likegame_profile_${DateTime.now().millisecondsSinceEpoch}.png';
          
          // 웹에서 다운로드
          ShareService.shareAsDownload(bytes, filename);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('프로필 이미지가 다운로드되었습니다'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          // toImage가 실패하면 텍스트 공유로 대체
          if (mounted) {
            Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
          }
          
          final userProvider = context.read<UserProvider>();
          final profile = userProvider.userProfile;
          
          String shareText = '🎮 LikeGame 프로필\n\n';
          shareText += '닉네임: ${profile?.nickname ?? '익명'}\n';
          shareText += '이메일: ${profile?.email ?? ''}\n\n';
          
          // 스탯 정보는 로컬 변수에서 가져오기
          shareText += '📈 성과\n';
          shareText += '스킬: $_totalSkillsCount개\n';
          shareText += '완료한 퀘스트: $_completedQuests개\n\n';
          shareText += 'LikeGame에서 나의 성장을 확인해보세요! 🚀';
          
          await ShareService.shareText(shareText, title: 'LikeGame 프로필');
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('프로필이 텍스트로 공유되었습니다'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        // 모바일 환경에서는 이미지 공유
        // 위젯을 이미지로 변환
        final RenderRepaintBoundary boundary = _profileImageKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
        final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        
        if (byteData == null) {
          if (mounted) {
            Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('이미지 생성에 실패했습니다'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // 로딩 다이얼로그 닫기
        if (mounted) {
          Navigator.of(context).pop();
        }

        final bytes = byteData.buffer.asUint8List();
        final filename = 'likegame_profile_${DateTime.now().millisecondsSinceEpoch}.png';
        
        try {
          await ShareService.shareAsFile(bytes, filename);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('공유 실패: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }

    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('공유 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showEditProfileDialog() async {
    final userProvider = context.read<UserProvider>();
    final nicknameController = TextEditingController(
      text: userProvider.userProfile?.nickname ?? '',
    );

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('프로필 수정'.withKoreanWordBreak),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nicknameController,
              decoration: const InputDecoration(
                labelText: '닉네임',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await userProvider.updateUserProfile(
                  userId: userProvider.currentUserId!,
                  nickname: nicknameController.text.trim(),
                );
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('프로필이 수정되었습니다'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('프로필 수정 실패: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('비밀번호 변경'.withKoreanWordBreak),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '현재 비밀번호',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '새 비밀번호',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '새 비밀번호 확인',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('새 비밀번호가 일치하지 않습니다'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                await _authService.changePassword(
                  currentPassword: currentPasswordController.text,
                  newPassword: newPasswordController.text,
                );
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('비밀번호가 변경되었습니다'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('비밀번호 변경 실패: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('변경'),
          ),
        ],
      ),
    );
  }

  Future<void> _showLogoutDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('로그아웃'.withKoreanWordBreak),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _authService.signOut();
                if (mounted) {
                  // 모든 화면을 닫고 로그인 화면으로 이동
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('로그아웃 실패: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteAccountDialog() async {
    final passwordController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('계정 탈퇴'.withKoreanWordBreak),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '정말 계정을 탈퇴하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
              style: TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '비밀번호 확인',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _authService.deleteAccount(passwordController.text);
                if (mounted) {
                  // 모든 화면을 닫고 로그인 화면으로 이동
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('계정 탈퇴 실패: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('탈퇴'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('프로필'.withKoreanWordBreak),
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareProfileAsImage,
              tooltip: '프로필 공유',
            ),
          ),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return Stack(
            children: [
              // 공유용 이미지 위젯 (화면 밖에 위치)
              Positioned(
                left: -10000,
                top: -10000,
                child: RepaintBoundary(
                  key: _profileImageKey,
                  child: Container(
                    width: 400,
                    color: Theme.of(context).scaffoldBackgroundColor,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // 실제 프로필 정보 카드
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Theme.of(context).primaryColor,
                                child: Icon(
                                  Icons.person,
                                  size: 24,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userProvider.userProfile?.nickname ?? '닉네임 없음',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _authService.currentUser?.email ?? '',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // 스탯 목록 카드
                        if (!_isLoadingStats && _skills.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardTheme.color,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ..._skills.take(5).map((skill) => _buildSkillItem(skill)),
                                if (_skills.length > 5)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      '외 ${_skills.length - 5}개 스탯 더 보기',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        
                        const SizedBox(height: 16),
                        
                        // 통계 정보 카드 (컴팩트)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              if (_isLoadingStats)
                                const CircularProgressIndicator()
                              else ...[
                                _buildCompactStatItem(
                                  icon: Icons.badge,
                                  title: '스킬',
                                  value: '$_totalSkillsCount',
                                  color: Colors.blue,
                                ),
                                _buildCompactStatItem(
                                  icon: Icons.task_alt,
                                  title: '완료한 퀘스트',
                                  value: '$_completedQuests',
                                  color: Colors.green,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // 실제 프로필 내용
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                
                // 실제 프로필 정보 카드
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Icon(
                          Icons.person,
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userProvider.userProfile?.nickname ?? '닉네임 없음',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _authService.currentUser?.email ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // 스탯 목록 카드
                if (!_isLoadingStats && _skills.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ..._skills.take(5).map((skill) => _buildSkillItem(skill)),
                        if (_skills.length > 5)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '외 ${_skills.length - 5}개 스탯 더 보기',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // 통계 정보 카드 (컴팩트)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (_isLoadingStats)
                        const CircularProgressIndicator()
                      else ...[
                                                        _buildCompactStatItem(
                                  icon: Icons.badge,
                                  title: '스킬',
                                  value: '$_totalSkillsCount',
                                  color: Colors.blue,
                                ),
                        _buildCompactStatItem(
                          icon: Icons.task_alt,
                          title: '완료한 퀘스트',
                          value: '$_completedQuests',
                          color: Colors.green,
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // 메뉴 리스트
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: Icons.edit,
                        title: '닉네임 변경'.withKoreanWordBreak,
                        onTap: _showEditProfileDialog,
                      ),
                      _buildMenuItem(
                        icon: Icons.lock,
                        title: '비밀번호 변경'.withKoreanWordBreak,
                        onTap: _showChangePasswordDialog,
                      ),
                      _buildMenuItem(
                        icon: Icons.privacy_tip,
                        title: '개인정보 처리방침'.withKoreanWordBreak,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const PrivacyPolicyScreen(),
                            ),
                          );
                        },
                      ),
                      Consumer<ThemeProvider>(
                        builder: (context, themeProvider, child) {
                          return _buildMenuItem(
                            icon: themeProvider.isDarkMode 
                                ? Icons.light_mode 
                                : Icons.dark_mode,
                            title: themeProvider.isDarkMode 
                                ? '라이트 모드'.withKoreanWordBreak
                                : '다크 모드'.withKoreanWordBreak,
                            onTap: () {
                              themeProvider.toggleTheme();
                            },
                          );
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.logout,
                        title: '로그아웃'.withKoreanWordBreak,
                        onTap: _showLogoutDialog,
                        isDestructive: true,
                      ),
                      _buildMenuItem(
                        icon: Icons.delete_forever,
                        title: '계정 영구 삭제'.withKoreanWordBreak,
                        onTap: _showDeleteAccountDialog,
                        isDestructive: true,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
        },
      ),
    );
  }



  Widget _buildCompactStatItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ],
    );
  }



  Widget _buildSkillItem(SkillProgress skill) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Text(
        '${skill.skillName} ${skill.rank}',
        style: TextStyle(
          fontSize: 16,
          color: _getRankColor(skill.rank),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }





  Color _getRankColor(String rank) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    switch (rank) {
      case 'F':
        return isDark ? const Color(0xFF9E9E9E) : Colors.grey;
      case 'E':
        return isDark ? const Color(0xFF8D6E63) : Colors.brown;
      case 'D':
        return isDark ? const Color(0xFFFF9800) : Colors.orange;
      case 'C':
        return isDark ? const Color(0xFFFFC107) : Colors.yellow[700]!;
      case 'B':
        return isDark ? const Color(0xFF03A9F4) : Colors.lightBlue;
      case 'A':
        return isDark ? const Color(0xFF9C27B0) : Colors.purple;
      default:
        return isDark ? const Color(0xFF9E9E9E) : Colors.grey;
    }
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          bottom: isLast ? const Radius.circular(12) : Radius.zero,
          top: Radius.zero,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: isLast ? null : Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isDestructive ? Colors.red : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDestructive ? Colors.red : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

