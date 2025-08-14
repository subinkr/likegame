import 'dart:async';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/stat_service.dart';
import '../services/event_service.dart';
import 'milestones_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  final StatService _statService = StatService();
  final EventService _eventService = EventService();
  StreamSubscription? _milestoneSubscription;
  
  UserProfile? _userProfile;
  List<SkillProgress> _topSkills = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _subscribeToMilestoneChanges();
  }

  @override
  void dispose() {
    _milestoneSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToMilestoneChanges() {
    _milestoneSubscription = _eventService.milestoneChangedStream.listen((_) {
      if (mounted) {
        _loadData(); // 마일스톤 변경 시 데이터 새로고침
      }
    });
  }

  Future<void> _loadData() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      final profile = await _authService.getUserProfile();
      
      final allSkills = await _statService.getUserSkillsProgress(user.id);

      if (mounted) {
        setState(() {
          _userProfile = profile;
          _topSkills = allSkills;
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
    // 현재 완료된 마일스톤 수에 따라 현재 등급 결정
    if (completedCount < 20) return 'F';
    if (completedCount <= 39) return 'E';
    if (completedCount <= 59) return 'D';
    if (completedCount <= 79) return 'C';
    if (completedCount <= 99) return 'B';
    if (completedCount >= 100) return 'A';
    return 'F';
  }

  // 다음 도전 등급 계산
  String _getNextChallengeRank(String currentRank) {
    switch (currentRank) {
      case 'F':
        return 'E';
      case 'E':
        return 'D';
      case 'D':
        return 'C';
      case 'C':
        return 'B';
      case 'B':
        return 'A';
      case 'A':
        return 'A'; // A등급 이상은 A등급 유지
      default:
        return 'E';
    }
  }

  // 현재 도전 중인 랭크의 진행도 계산
  double _getCurrentRankProgress(SkillProgress skill) {
    final challengeRank = _getNextChallengeRank(skill.rank);
    final rankLevels = _getRankLevels();
    final levels = rankLevels[challengeRank];
    
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
    final challengeRank = _getNextChallengeRank(skill.rank);
    final rankLevels = _getRankLevels();
    final levels = rankLevels[challengeRank];
    
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

  // 스탯 카드 클릭 시 해당 스탯의 현재 도전 중인 등급 마일스톤으로 이동
  void _navigateToSkillMilestones(SkillProgress skillProgress) {
    // 현재 등급에 따라 다음 도전 등급 결정
    final currentRank = skillProgress.rank;
    final challengeRank = _getNextChallengeRank(currentRank);
    final rankLevels = _getRankLevels();
    final levels = rankLevels[challengeRank];
    
    if (levels != null) {
      // Skill 객체 생성 (필요한 정보만 포함)
      final skill = Skill(
        id: skillProgress.skillId,
        name: skillProgress.skillName,
        key: skillProgress.skillName.toLowerCase().replaceAll(' ', '_'),
        createdAt: DateTime.now(),
      );
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MilestonesScreen(
            skill: skill,
            rank: challengeRank,
            startLevel: levels['start']!,
            endLevel: levels['end']!,
            onMilestoneChanged: _loadData, // 마일스톤 변경 시 데이터 새로고침
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
            
            const SizedBox(height: 20),
            
            // 스탯 섹션
            _buildStatsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.person,
              size: 30,
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
                     fontSize: 20,
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
            '스탯을 성장시켜 랭크를 올려보세요!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.list_alt,
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              '스탯',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_topSkills.isEmpty)
          _buildEmptyState('아직 완료한 마일스톤이 없습니다.\n스탯을 선택해서 시작해보세요!')
        else
          _buildStatsList(),
      ],
    );
  }

  Widget _buildStatsList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
        children: _topSkills.map((skill) => _buildStatsListItem(skill)).toList(),
      ),
    );
  }

  Widget _buildStatsListItem(SkillProgress skill) {
    final isLast = _topSkills.last == skill;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToSkillMilestones(skill),
        borderRadius: BorderRadius.vertical(
          bottom: isLast ? const Radius.circular(12) : Radius.zero,
          top: _topSkills.first == skill ? const Radius.circular(12) : Radius.zero,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: isLast ? null : Border(
              bottom: BorderSide(
                color: Colors.grey.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getRankColor(skill.rank),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  skill.rank,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  skill.skillName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '${_getCurrentRankProgressCount(skill)}/${_getNextRankTarget(skill)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
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

  int _getNextRankTarget(SkillProgress skill) {
    // 각 등급마다 20개씩 마일스톤을 클리어하면 됨
    return 20;
  }

  int _getCurrentRankProgressCount(SkillProgress skill) {
    final completedCount = skill.completedCount;
    
    // 각 등급마다 20개씩이므로, 현재 등급에서 클리어한 수를 계산
    switch (skill.rank) {
      case 'F':
        return completedCount; // 0-19
      case 'E':
        return completedCount - 20; // 20-39에서 20을 빼면 0-19
      case 'D':
        return completedCount - 40; // 40-59에서 40을 빼면 0-19
      case 'C':
        return completedCount - 60; // 60-79에서 60을 빼면 0-19
      case 'B':
        return completedCount - 80; // 80-99에서 80을 빼면 0-19
      case 'A':
        return completedCount - 100; // 100+에서 100을 빼면 0+
      default:
        return completedCount;
    }
  }
}
