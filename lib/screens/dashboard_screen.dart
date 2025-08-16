import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/stat_service.dart';
import '../services/priority_service.dart';
import '../services/event_service.dart';
import '../utils/text_utils.dart';
import 'milestones_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final StatService _statService = StatService();
  final PriorityService _priorityService = PriorityService();
  final EventService _eventService = EventService();
  final SupabaseClient _supabase = Supabase.instance.client;
  StreamSubscription? _milestoneSubscription;
  
  List<SkillProgress> _skillsWithMilestones = [];
  List<UserStatPriority> _priorities = [];
  List<StatPerformance> _performanceStats = [];
  List<Achievement> _achievements = [];
  bool _isLoading = true;
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // 성취 탭 제거로 2개로 변경
    _loadData();
    _subscribeToMilestoneChanges();
  }

  @override
  void dispose() {
    _milestoneSubscription?.cancel();
    _tabController.dispose();
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
      if (user == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final allSkills = await _statService.getUserSkillsProgress(user.id);
      final priorities = await _priorityService.getUserStatPriorities(user.id);
      final performanceStats = await _statService.getStatPerformance(user.id);
      // final achievements = await _statService.getUserAchievements(user.id); // 일시적으로 비활성화

      // 마일스톤이 있는 스탯만 필터링
      final skillsWithMilestones = allSkills.where((skill) => skill.completedCount >= 0).toList();

      if (mounted) {
        setState(() {
          _skillsWithMilestones = skillsWithMilestones;
          _priorities = priorities;
          _performanceStats = performanceStats;
          // _achievements = achievements; // 일시적으로 비활성화
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

  // 우선순위 순서대로 정렬된 스탯 목록 생성 (정순)
  List<SkillProgress> get _sortedSkills {
    final Map<String, int> priorityMap = {};
    
    // 우선순위 매핑 생성
    for (final priority in _priorities) {
      priorityMap[priority.statId] = priority.priorityOrder;
    }
    
    // 우선순위가 있는 스탯들을 우선순위 순으로 정렬
    final sortedSkills = List<SkillProgress>.from(_skillsWithMilestones);
    sortedSkills.sort((a, b) {
      final aPriority = priorityMap[a.skillId] ?? 999;
      final bPriority = priorityMap[b.skillId] ?? 999;
      return aPriority.compareTo(bPriority);
    });
    
    return sortedSkills;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 탭 바
                Container(
                  color: Theme.of(context).primaryColor,
                  child: TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: '스탯', icon: Icon(Icons.analytics)),
                      Tab(text: '성과', icon: Icon(Icons.trending_up)),
                      // Tab(text: '성취', icon: Icon(Icons.emoji_events)), // 일시적으로 비활성화
                    ],
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    indicatorColor: Colors.white,
                  ),
                ),
                
                // 탭 뷰
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildStatsTab(),
                      _buildPerformanceTab(),
                      // _buildAchievementsTab(), // 일시적으로 비활성화
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 목표 요약 카드
          if (_skillsWithMilestones.any((skill) => skill.targetLevel != null))
            _buildGoalsSummaryCard(),
          
          const SizedBox(height: 16),
          
          // 스탯 목록
          Text(
            '내 스탯'.withKoreanWordBreak,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // 스탯 카드들
          ..._sortedSkills.map((skill) => _buildStatCard(skill)),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 전체 성과 요약
          _buildOverallPerformanceCard(),
          
          const SizedBox(height: 16),
          
          // 스탯별 성과
          Text(
            '스탯별 성과'.withKoreanWordBreak,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          if (_performanceStats.isEmpty)
            _buildEmptyPerformanceMessage()
          else
            ..._performanceStats.map((performance) => _buildPerformanceCard(performance)),
        ],
      ),
    );
  }

  Widget _buildEmptyPerformanceMessage() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.trending_up,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '성과 데이터를 준비 중입니다'.withKoreanWordBreak,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '마일스톤을 달성하면 성과 통계가 표시됩니다'.withKoreanWordBreak,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 성취 요약
          _buildAchievementsSummaryCard(),
          
          const SizedBox(height: 16),
          
          // 성취 배지들
          Text(
            '획득한 배지'.withKoreanWordBreak,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _achievements.length,
            itemBuilder: (context, index) {
              return _buildAchievementCard(_achievements[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsSummaryCard() {
    final goals = _skillsWithMilestones.where((skill) => skill.targetLevel != null).toList();
    final completedGoals = goals.where((skill) => skill.targetProgressPercentage >= 1.0).length;
    final upcomingGoals = goals.where((skill) => 
        skill.targetDate != null && skill.daysUntilTarget != null && skill.daysUntilTarget! <= 7
    ).length;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  '목표 현황'.withKoreanWordBreak,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildGoalStat('전체 목표', goals.length.toString(), Icons.flag),
                _buildGoalStat('달성 완료', completedGoals.toString(), Icons.check_circle, Colors.green),
                _buildGoalStat('임박 목표', upcomingGoals.toString(), Icons.warning, Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalStat(String label, String value, IconData icon, [Color? color]) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.grey, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildStatCard(SkillProgress skill) {
    final rankColor = _getRankColor(skill.rank);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Stat 객체 생성
          final stat = Stat(
            id: skill.skillId,
            name: skill.skillName,
            key: skill.skillId,
            createdAt: DateTime.now(),
          );
          
          // 랭크에 따른 시작/끝 레벨 계산
          final rankLevels = _getRankLevels();
          final currentRank = skill.rank;
          final nextRank = _getNextChallengeRank(currentRank);
          final levels = rankLevels[nextRank] ?? {'start': 1, 'end': 20};
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MilestonesScreen(
                skill: stat,
                rank: nextRank,
                startLevel: levels['start']!,
                endLevel: levels['end']!,
              ),
            ),
          ).then((_) => _loadData());
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      skill.skillName.withKoreanWordBreak,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: rankColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: rankColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      skill.rank,
                      style: TextStyle(
                        color: rankColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // 진행도 바
              LinearProgressIndicator(
                value: skill.progressPercentage,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(rankColor),
                minHeight: 8,
              ),
              
              const SizedBox(height: 8),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${skill.completedCount}/${skill.totalCount}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    '${(skill.progressPercentage * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              // 목표 정보 (있는 경우)
              if (skill.targetLevel != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.flag, color: Colors.blue, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '목표: ${skill.targetLevel}레벨',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            if (skill.targetDate != null && skill.daysUntilTarget != null)
                              Text(
                                '${skill.daysUntilTarget}일 남음',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ),
                      LinearProgressIndicator(
                        value: skill.targetProgressPercentage,
                        backgroundColor: Colors.blue.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                        minHeight: 4,
                      ),
                    ],
                  ),
                ),
              ],
              
              // 스트릭 정보 (있는 경우)
              if (skill.currentStreak > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.local_fire_department, color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${skill.currentStreak}일 연속',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (skill.bestStreak > skill.currentStreak) ...[
                      const SizedBox(width: 8),
                      Text(
                        '(최고: ${skill.bestStreak}일)',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverallPerformanceCard() {
    final totalCompleted = _performanceStats.fold<int>(0, (sum, stat) => sum + stat.totalCompleted);
    final weeklyCompleted = _performanceStats.fold<int>(0, (sum, stat) => sum + stat.weeklyCompleted);
    final monthlyCompleted = _performanceStats.fold<int>(0, (sum, stat) => sum + stat.monthlyCompleted);
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  '전체 성과'.withKoreanWordBreak,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPerformanceStat('총 달성', totalCompleted.toString(), Icons.check_circle),
                _buildPerformanceStat('이번 주', weeklyCompleted.toString(), Icons.calendar_today),
                _buildPerformanceStat('이번 달', monthlyCompleted.toString(), Icons.calendar_month),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildPerformanceCard(StatPerformance performance) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  performance.statName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '총 ${performance.totalCompleted}회',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildPerformanceMetric(
                    '이번 주',
                    performance.weeklyCompleted.toString(),
                    performance.weeklyGrowth,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPerformanceMetric(
                    '이번 달',
                    performance.monthlyCompleted.toString(),
                    performance.monthlyGrowth,
                  ),
                ),
              ],
            ),
            
            if (performance.currentStreak > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.local_fire_department, color: Colors.orange, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${performance.currentStreak}일 연속',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (performance.bestStreak > performance.currentStreak) ...[
                    const SizedBox(width: 8),
                    Text(
                      '(최고: ${performance.bestStreak}일)',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMetric(String label, String value, double growth) {
    final isPositive = growth > 0;
    final isNegative = growth < 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (growth != 0) ...[
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                size: 12,
                color: isPositive ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 2),
              Text(
                '${growth.abs().toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 10,
                  color: isPositive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAchievementsSummaryCard() {
    final unlockedCount = _achievements.length;
    final totalAchievements = 10; // 기본 배지 개수
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  '성취 현황'.withKoreanWordBreak,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAchievementStat('획득 배지', unlockedCount.toString(), Icons.emoji_events),
                _buildAchievementStat('달성률', '${((unlockedCount / totalAchievements) * 100).toInt()}%', Icons.percent),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              achievement.icon,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              achievement.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              achievement.description,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (achievement.unlockedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                '${achievement.unlockedAt!.month}/${achievement.unlockedAt!.day}',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
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

  // 우선순위 순서 업데이트
  Future<void> _updatePriorityOrder(SkillProgress skill, int newOrder) async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      await _priorityService.setStatPriority(
        userId: user.id,
        statId: skill.skillId,
        priorityOrder: newOrder,
      );

      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('우선순위 업데이트 실패: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
