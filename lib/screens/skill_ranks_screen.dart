import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/skill_service.dart';
import 'milestones_screen.dart';

class SkillRanksScreen extends StatefulWidget {
  final Skill skill;

  const SkillRanksScreen({
    super.key,
    required this.skill,
  });

  @override
  State<SkillRanksScreen> createState() => _SkillRanksScreenState();
}

class _SkillRanksScreenState extends State<SkillRanksScreen> {
  final AuthService _authService = AuthService();
  final SkillService _skillService = SkillService();
  
  SkillProgress? _skillProgress;
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

      final progress = await _skillService.getUserSkillProgress(user.id, widget.skill.id);

      if (mounted) {
        setState(() {
          _skillProgress = progress;
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

  bool _isCurrentRank(RankData rankData) {
    // 현재 도전 중인 랭크는 현재 달성한 등급보다 1단계 높은 등급
    final currentRankLevel = _getRankLevel(rankData.currentRank);
    final targetRankLevel = _getRankLevel(rankData.rank);
    return targetRankLevel == currentRankLevel + 1;
  }

  // 랭크가 완료되었는지 확인 (100% 진행률)
  bool _isRankCompleted(RankData rankData) {
    return rankData.progressPercentage >= 1.0;
  }

  // 랭크가 잠겨있는지 확인
  bool _isRankLocked(RankData rankData) {
    // 현재 달성한 등급보다 1단계 높은 등급까지만 열려있음
    final currentRankLevel = _getRankLevel(rankData.currentRank);
    final targetRankLevel = _getRankLevel(rankData.rank);
    return targetRankLevel > currentRankLevel + 1;
  }

  // 등급별 레벨 반환
  int _getRankLevel(String rank) {
    switch (rank) {
      case 'F': return 0;
      case 'E': return 1;
      case 'D': return 2;
      case 'C': return 3;
      case 'B': return 4;
      case 'A': return 5;
      default: return 0;
    }
  }

  // 현재 도전 중인 등급 계산
  String _getCurrentChallengeRank() {
    final completedCount = _skillProgress?.completedCount ?? 0;
    if (completedCount == 0) return 'E';
    if (completedCount < 20) return 'E';
    if (completedCount < 40) return 'D';
    if (completedCount < 60) return 'C';
    if (completedCount < 80) return 'B';
    if (completedCount < 100) return 'A';
    return 'A'; // A등급 이상은 A등급 유지
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

  List<RankData> _generateRankData() {
    final completedCount = _skillProgress?.completedCount ?? 0;
    final currentRank = _skillProgress?.rank ?? 'F';
    
    return [
      RankData('E', 1, 20, completedCount, currentRank),
      RankData('D', 21, 40, completedCount, currentRank),
      RankData('C', 41, 60, completedCount, currentRank),
      RankData('B', 61, 80, completedCount, currentRank),
      RankData('A', 81, 100, completedCount, currentRank),
    ];
  }

  void _navigateToMilestones(String rank, int startLevel, int endLevel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MilestonesScreen(
          skill: widget.skill,
          rank: rank,
          startLevel: startLevel,
          endLevel: endLevel,
        ),
      ),
    ).then((_) {
      // 마일스톤 화면에서 돌아왔을 때 데이터 새로고침
      _loadData();
    });
  }

  // 스킬 카드 클릭 시 현재 도전 중인 등급의 마일스톤으로 이동
  void _navigateToCurrentChallengeMilestones() {
    final challengeRank = _getCurrentChallengeRank();
    final rankLevels = _getRankLevels();
    final levels = rankLevels[challengeRank];
    
    if (levels != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MilestonesScreen(
            skill: widget.skill,
            rank: challengeRank,
            startLevel: levels['start']!,
            endLevel: levels['end']!,
          ),
        ),
      ).then((_) {
        // 마일스톤 화면에서 돌아왔을 때 데이터 새로고침
        _loadData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.skill.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 스킬 정보 헤더
                    _buildSkillHeader(),
                    
                    const SizedBox(height: 24),
                    
                    // 랭크별 진행상황
                    Text(
                      '랭크별 진행상황',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    ..._generateRankData().map((rankData) => _buildRankCard(rankData)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSkillHeader() {
    final progress = _skillProgress;
    final currentRank = progress?.rank ?? 'F';
    final completedCount = progress?.completedCount ?? 0;
    final totalCount = progress?.totalCount ?? 100;
    final progressPercentage = progress?.progressPercentage ?? 0.0;

    return GestureDetector(
      onTap: _navigateToCurrentChallengeMilestones,
      child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getRankColor(currentRank),
            _getRankColor(currentRank).withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _getRankColor(currentRank).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 현재 랭크
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Center(
              child: Text(
                currentRank,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.skill.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.8),
                size: 16,
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Text(
            widget.skill.category?.name ?? '',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 전체 진행률
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '전체 진행률',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$completedCount/$totalCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progressPercentage,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 6,
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildRankCard(RankData rankData) {
    final isLocked = _isRankLocked(rankData);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isLocked ? Colors.grey[100] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: isLocked ? 1 : 2,
        shadowColor: Colors.black.withOpacity(0.1),
        child: InkWell(
          onTap: isLocked ? null : () => _navigateToMilestones(
            rankData.rank,
            rankData.startLevel,
            rankData.endLevel,
          ),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 랭크 아이콘
                Stack(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isLocked ? Colors.grey[400]! : _getRankColor(rankData.rank),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Center(
                        child: isLocked 
                          ? const Icon(
                              Icons.lock,
                              color: Colors.white,
                              size: 24,
                            )
                          : Text(
                              rankData.rank,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                      ),
                    ),
                    if (_isRankCompleted(rankData) && !isLocked)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(width: 16),
                
                // 랭크 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${rankData.rank} 등급',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isLocked 
                                ? Colors.grey[400] 
                                : (_isCurrentRank(rankData) ? _getRankColor(rankData.rank) : Colors.black),
                            ),
                          ),
                          if (!isLocked)
                            Text(
                              '${rankData.completedInRank}/${rankData.totalInRank}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      Text(
                        isLocked ? '잠겨있음' : '레벨 ${rankData.startLevel}-${rankData.endLevel}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isLocked ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // 진행률 바
                      if (!isLocked)
                        LinearProgressIndicator(
                          value: rankData.progressPercentage,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation(_getRankColor(rankData.rank)),
                          minHeight: 6,
                        )
                      else
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // 화살표
                if (!isLocked)
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  )
                else
                  Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: Colors.grey[400],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RankData {
  final String rank; // 도전 중인 등급
  final int startLevel;
  final int endLevel;
  final int totalCompleted;
  final String currentRank; // 현재 달성한 등급

  RankData(this.rank, this.startLevel, this.endLevel, this.totalCompleted, this.currentRank);

  int get totalInRank => endLevel - startLevel + 1;

  int get completedInRank {
    if (totalCompleted < startLevel) return 0;
    if (totalCompleted >= endLevel) return totalInRank;
    return totalCompleted - startLevel + 1;
  }

  double get progressPercentage {
    return completedInRank / totalInRank;
  }
}
