import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'dashboard_screen.dart';
import 'skills_screen.dart';
import 'quests_screen.dart';
import 'template_list_screen.dart';
import 'profile_screen.dart';
import '../utils/text_utils.dart';
import '../providers/user_provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late final GlobalKey<QuestsScreenState> _questsScreenKey;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _questsScreenKey = GlobalKey<QuestsScreenState>();
    _screens = [
      const DashboardScreen(),
      const SkillsScreen(),
      QuestsScreen(key: _questsScreenKey),
    ];
  }

          final List<String> _titles = [
            '스탯'.withKoreanWordBreak,
            '스킬'.withKoreanWordBreak,
            '퀘스트'.withKoreanWordBreak,
          ];



  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // 탈퇴한 계정 메시지 표시
        if (userProvider.deletedAccountMessage != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(userProvider.deletedAccountMessage!),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
                action: SnackBarAction(
                  label: '확인',
                  textColor: Colors.white,
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
              ),
            );
          });
        }
        
        return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          // 퀘스트 화면일 때만 템플릿 관련 버튼 표시
          if (_currentIndex == 2) ...[
            IconButton(
              icon: const Icon(Icons.store),
              onPressed: () => _showTemplateMarketplace(),
              tooltip: '템플릿 목록',
            ),
          ],
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
              tooltip: '프로필',
            ),
          ),
        ],
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                        _buildNavItem(
                          icon: Icons.description,
                          label: '스탯'.withKoreanWordBreak,
                          index: 0,
                        ),
                        _buildNavItem(
                          icon: Icons.badge,
                          label: '스킬'.withKoreanWordBreak,
                          index: 1,
                        ),
                        _buildNavItem(
                          icon: Icons.task_alt,
                          label: '퀘스트'.withKoreanWordBreak,
                          index: 2,
                        ),
                      ],
            ),
          ),
        ),
      ),
        );
      },
    );
  }

  void _showTemplateMarketplace() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TemplateListScreen(),
      ),
    );
    
    // 퀘스트가 생성되었다면 퀘스트 화면의 데이터를 새로고침
    if (result == true) {
      // 퀘스트 화면으로 이동
      setState(() {
        _currentIndex = 2;
      });
      
      // 화면 전환 후 새로고침
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _questsScreenKey.currentState?.refreshData();
      });
    }
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final color = isSelected 
        ? Theme.of(context).primaryColor 
        : isDark
            ? Theme.of(context).colorScheme.onSurface.withOpacity(0.8)
            : Theme.of(context).colorScheme.onSurface.withOpacity(0.7);

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark 
                  ? Theme.of(context).primaryColor.withOpacity(0.2)
                  : Theme.of(context).primaryColor.withOpacity(0.1))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
