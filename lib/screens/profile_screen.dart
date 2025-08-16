import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/stat_service.dart';
import '../services/quest_service.dart';
import '../utils/text_utils.dart';
import '../providers/user_provider.dart';
import '../providers/theme_provider.dart';
import '../models/models.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final StatService _statService = StatService();
  final QuestService _questService = QuestService();
  
  List<SkillProgress> _skills = [];
  int _completedQuests = 0;
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

      final skills = await _statService.getUserSkillsProgress(userId);
      final quests = await _questService.getUserQuests(userId);
      final completedQuests = quests.where((quest) => quest.isCompleted).length;

      if (mounted) {
        setState(() {
          _skills = skills;
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
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 프로필 정보 카드
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
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
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          userProvider.userProfile?.nickname ?? '닉네임 없음',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _authService.currentUser?.email ?? '',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 통계 정보 카드
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '활동 통계'.withKoreanWordBreak,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_isLoadingStats)
                          const Center(child: CircularProgressIndicator())
                        else
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                  icon: Icons.badge,
                                  title: '스킬',
                                  value: '${_skills.length}',
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildStatItem(
                                  icon: Icons.task_alt,
                                  title: '완료한 퀘스트',
                                  value: '$_completedQuests개',
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 스탯 목록 카드
                  if (!_isLoadingStats && _skills.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '스탯'.withKoreanWordBreak,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
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
          );
        },
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
