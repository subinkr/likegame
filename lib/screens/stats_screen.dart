import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/skill_service.dart';
import 'milestones_screen.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final AuthService _authService = AuthService();
  final SkillService _skillService = SkillService();
  
  UserProfile? _userProfile;
  List<SkillProgress> _topSkills = [];
  List<SkillProgress> _recentSkills = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      final profile = await _authService.getUserProfile();
      
      final topSkills = await _skillService.getTopSkills(user.id);
      final recentSkills = await _skillService.getRecentlyGrownSkills(user.id);

      if (mounted) {
        setState(() {
          _userProfile = profile;
          _topSkills = topSkills;
          _recentSkills = recentSkills;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('데이터 로드 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getRankColor(String rank) {
    switch (rank) {
      case 'F':
        return Colors.grey;
      case 'E':
        return Colors.brown;
      case 'D':
        return Colors.orange;
      case 'C':
        return Colors.yellow[700]!;
      case 'B':
        return Colors.lightBlue;
      case 'A':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  // 현재 도전 중인 등급 계산
  String _getCurrentChallengeRank(int completedCount) {
    if (completedCount == 0) return 'E';
    if (completedCount < 20) return 'E';
    if (completedCount < 40) return 'D';
    if (completedCount < 60) return 'C';
    if (completedCount < 80) return 'B';
    if (completedCount < 100) return 'A';
    return 'A'; // A등급 이상은 A등급 유지
  }

  // 현재 도전 중인 랭크의 진행도 계산
  double _getCurrentRankProgress(SkillProgress skill) {
    final currentRank = _getCurrentChallengeRank(skill.completedCount);
    final rankLevels = _getRankLevels();
    final levels = rankLevels[currentRank];
    
    if (levels == null) return 0.0;
    
    final startLevel = levels['start']!;
    final endLevel = levels['end']!;
    final totalInRank = endLevel - startLevel + 1;
    
    if (skill.completedCount < startLevel) return 0.0;
    if (skill.completedCount >= endLevel) return 1.0;
    
    final completedInRank = skill.completedCount - startLevel + 1;
    return completedInRank / totalInRank;
  }

  // 현재 도전 중인 랭크의 완료 개수 계산
  String _getCurrentRankProgressText(SkillProgress skill) {
    final currentRank = _getCurrentChallengeRank(skill.completedCount);
    final rankLevels = _getRankLevels();
    final levels = rankLevels[currentRank];
    
    if (levels == null) return '0/0';
    
    final startLevel = levels['start']!;
    final endLevel = levels['end']!;
    final totalInRank = endLevel - startLevel + 1;
    
    if (skill.completedCount < startLevel) return '0/$totalInRank';
    if (skill.completedCount >= endLevel) return '$totalInRank/$totalInRank';
    
    final completedInRank = skill.completedCount - startLevel + 1;
    return '$completedInRank/$totalInRank';
  }

  // 등급별 시작/끝 레벨
  Map<String, Map<String, int>> _getRankLevels() {
    return {
      'E': {'start': 1, 'end': 20},
      'D': {'start': 21, 'end': 40},
      'C': {'start': 41, 'end': 60},
      'B': {'start': 61, 'end': 80},
      'A': {'start': 81, 'end': 100},
    };
  }

  // 스킬 카드 클릭 시 해당 스킬의 현재 도전 중인 등급 마일스톤으로 이동
  void _navigateToSkillMilestones(SkillProgress skillProgress) {
    final challengeRank = _getCurrentChallengeRank(skillProgress.completedCount);
    final rankLevels = _getRankLevels();
    final levels = rankLevels[challengeRank];
    
    if (levels != null) {
      // Skill 객체 생성 (필요한 정보만 포함)
      final skill = Skill(
        id: skillProgress.skillId,
        name: skillProgress.skillName,
        categoryId: '',
        key: skillProgress.skillName.toLowerCase().replaceAll(' ', '_'),
        createdAt: DateTime.now(),
        category: Category(
          id: '', 
          name: skillProgress.categoryName,
          createdAt: DateTime.now(),
        ),
      );
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MilestonesScreen(
            skill: skill,
            rank: challengeRank,
            startLevel: levels['start']!,
            endLevel: levels['end']!,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 사용자 정보
            _buildUserSection(),
            
            const SizedBox(height: 32),
            
            // 상위 스킬 섹션
            _buildTopSkillsSection(),
            
            const SizedBox(height: 32),
            
            // 최근 성장 스킬 섹션
            _buildRecentSkillsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.person,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _showNicknameEditDialog,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                                 Text(
                   _userProfile?.nickname ?? 'anonymous',
                   style: const TextStyle(
                     fontSize: 24,
                     fontWeight: FontWeight.bold,
                     color: Colors.white,
                   ),
                 ),
                const SizedBox(width: 8),
                Icon(
                  Icons.edit,
                  color: Colors.white.withOpacity(0.8),
                  size: 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '스킬을 성장시켜 랭크를 올려보세요!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSkillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.emoji_events,
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              '상위 스킬',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_topSkills.isEmpty)
          _buildEmptyState('아직 완료한 마일스톤이 없습니다.\n스킬을 선택해서 시작해보세요!')
        else
          Column(
            children: _topSkills.map((skill) => _buildSkillCard(skill)).toList(),
          ),
      ],
    );
  }

  Widget _buildRecentSkillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.trending_up,
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              '최근 성장한 스킬',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_recentSkills.isEmpty)
          _buildEmptyState('최근 성장한 스킬이 없습니다.\n마일스톤을 완료해보세요!')
        else
          Column(
            children: _recentSkills.map((skill) => _buildSkillCard(skill)).toList(),
          ),
      ],
    );
  }

  Widget _buildSkillCard(SkillProgress skill) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        child: InkWell(
          onTap: () => _navigateToSkillMilestones(skill),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 랭크 아이콘
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _getRankColor(skill.rank),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Center(
              child: Text(
                skill.rank,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // 스킬 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        skill.skillName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey[400],
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  skill.categoryName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                
                // 현재 도전 중인 랭크 진행률
                Row(
                  children: [
                    Text(
                      '${_getCurrentChallengeRank(skill.completedCount)}등급 진행도',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _getCurrentRankProgressText(skill),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 4),
                
                // 진행률 바
                LinearProgressIndicator(
                  value: _getCurrentRankProgress(skill),
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(_getRankColor(_getCurrentChallengeRank(skill.completedCount))),
                  minHeight: 6,
                ),
              ],
            ),
          ),
        ],
      ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _showNicknameEditDialog() async {
    final TextEditingController nicknameController = TextEditingController(
      text: _userProfile?.nickname ?? '',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('닉네임 수정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('새로운 닉네임을 입력해주세요'),
            const SizedBox(height: 16),
            TextField(
              controller: nicknameController,
              decoration: const InputDecoration(
                labelText: '닉네임',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  Navigator.of(context).pop(value.trim());
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              final nickname = nicknameController.text.trim();
              if (nickname.isNotEmpty) {
                Navigator.of(context).pop(nickname);
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        await _authService.updateProfile(nickname: result);
        await _loadData(); // 프로필 다시 로드
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('닉네임이 수정되었습니다.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('닉네임 수정 실패: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
