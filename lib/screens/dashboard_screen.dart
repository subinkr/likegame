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

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  final StatService _statService = StatService();
  final PriorityService _priorityService = PriorityService();
  final EventService _eventService = EventService.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  StreamSubscription? _milestoneSubscription;
  
  List<SkillProgress> _skillsWithMilestones = [];
  List<UserStatPriority> _priorities = [];
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

      // 마일스톤이 있는 스탯만 필터링
      final skillsWithMilestones = allSkills.where((skill) => skill.completedCount >= 0).toList();

      if (mounted) {
        setState(() {
          _skillsWithMilestones = skillsWithMilestones;
          _priorities = priorities;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
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
    
    // 우선순위 정순으로 정렬 (우선순위가 없으면 ㄱㄴㄷ 순서)
    final sortedSkills = List<SkillProgress>.from(_skillsWithMilestones);
    sortedSkills.sort((a, b) {
      final aPriority = priorityMap[a.skillId] ?? 999;
      final bPriority = priorityMap[b.skillId] ?? 999;
      
      // 우선순위가 같으면 ㄱㄴㄷ 순서로 정렬
      if (aPriority == bPriority) {
        return a.skillName.compareTo(b.skillName);
      }
      
      return aPriority.compareTo(bPriority);
    });
    
    return sortedSkills;
  }

  Future<void> _updatePriorityOrder(String skillId, int newOrder) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('로그인이 필요합니다'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      final userId = user.id;
      
      // 새로운 순서로 정렬된 스탯 목록 생성
      final List<SkillProgress> newOrderedSkills = [];
      
      // 드래그된 아이템을 제외한 나머지 아이템들
      final otherSkills = _sortedSkills.where((skill) => skill.skillId != skillId).toList();
      
      // newOrder 위치에 드래그된 아이템 삽입
      for (int i = 0; i < _sortedSkills.length; i++) {
        if (i == newOrder) {
          // 드래그된 아이템을 이 위치에 삽입
          try {
            final draggedSkill = _sortedSkills.firstWhere((skill) => skill.skillId == skillId);
            newOrderedSkills.add(draggedSkill);
          } catch (e) {
            // skillId를 찾을 수 없는 경우 (이론적으로는 발생하지 않아야 함)
            continue;
          }
        }
        
        // 다른 아이템들 추가
        if (i < otherSkills.length) {
          newOrderedSkills.add(otherSkills[i]);
        }
      }
      
      // 새로운 우선순위로 업데이트
      final List<Map<String, dynamic>> updates = [];
      for (int i = 0; i < newOrderedSkills.length; i++) {
        updates.add({
          'user_id': userId,
          'stat_id': newOrderedSkills[i].skillId,
          'priority_order': i,
        });
      }
      
      // 기존 우선순위 모두 삭제
      await _supabase
          .from('user_stat_priorities')
          .delete()
          .eq('user_id', userId);
      
      // 새로운 우선순위들 한 번에 삽입
      if (updates.isNotEmpty) {
        await _supabase
            .from('user_stat_priorities')
            .insert(updates);
      }
      
      // 데이터 다시 로드
      await _loadData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('우선순위가 업데이트되었습니다'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('우선순위 업데이트 실패: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
      final skill = Stat(
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
    print('DashboardScreen: build 호출됨 - isLoading: $_isLoading');
    print('DashboardScreen: 스킬 수: ${_skillsWithMilestones.length}');
    
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    try {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 스탯 섹션
              _buildStatsSection(),
            ],
          ),
        ),
      );
    } catch (e, stackTrace) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('화면 렌더링 오류: ${e.toString()}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                  });
                  _loadData();
                },
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }
  }



  Widget _buildStatsSection() {
    try {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_sortedSkills.isEmpty)
            _buildEmptyState('마일스톤이 있는 스탯이 없습니다.\n스탯을 선택해서 시작해보세요!')
          else
            _buildStatsList(),
        ],
      );
    } catch (e, stackTrace) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text('스탯 섹션 렌더링 오류: ${e.toString()}'),
          ],
        ),
      );
    }
  }

  Widget _buildStatsList() {
    try {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _sortedSkills.length,
          buildDefaultDragHandles: false,
          onReorder: (oldIndex, newIndex) {
            // ReorderableListView의 인덱스 조정
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            
            // 실제 원하는 위치 계산
            int targetIndex = newIndex;
            if (oldIndex < newIndex) {
              // 아래로 드래그할 때는 그대로
              targetIndex = newIndex;
            } else {
              // 위로 드래그할 때는 그대로
              targetIndex = newIndex;
            }
            
            final skill = _sortedSkills[oldIndex];
            _updatePriorityOrder(skill.skillId, targetIndex);
          },
          itemBuilder: (context, index) {
            try {
              final skill = _sortedSkills[index];
              
              return ReorderableDragStartListener(
                key: ValueKey(skill.skillId),
                index: index,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _navigateToSkillMilestones(skill),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // 랭크 배지
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getRankColor(skill.rank),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: _getRankColor(skill.rank).withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
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
                            
                            // 스탯 이름
                            Expanded(
                              child: Text(
                                skill.skillName.withKoreanWordBreak,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            
                            // 진행도
                            Text(
                              '${_getCurrentRankProgressCount(skill)}/${_getNextRankTarget(skill)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            } catch (e, stackTrace) {
              return Container(
                padding: const EdgeInsets.all(16),
                child: Text('스킬 렌더링 오류: ${e.toString()}'),
              );
            }
          },
        ),
      );
    } catch (e, stackTrace) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text('스탯 목록 렌더링 오류: ${e.toString()}'),
          ],
        ),
      );
    }
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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
        return (completedCount - 20).clamp(0, 19); // 20-39에서 20을 빼면 0-19
      case 'D':
        return (completedCount - 40).clamp(0, 19); // 40-59에서 40을 빼면 0-19
      case 'C':
        return (completedCount - 60).clamp(0, 19); // 60-79에서 60을 빼면 0-19
      case 'B':
        return (completedCount - 80).clamp(0, 19); // 80-99에서 80을 빼면 0-19
      case 'A':
        return (completedCount - 100).clamp(0, 19); // 100+에서 100을 빼면 0+
      default:
        return completedCount;
    }
  }
}
