import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class StatService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 모든 스탯 가져오기
  Future<List<Stat>> getAllStats() async {
    try {
      final response = await _supabase
          .from('stats')
          .select()
          .order('name');

      return (response as List)
          .map((stat) => Stat.fromJson(stat))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // 모든 스탯 가져오기 (마일스톤이 있는 스탯만)
  Future<List<Stat>> getSkills({String? searchQuery}) async {
    try {
      // 먼저 마일스톤이 있는 스탯 ID들을 가져오기
              final milestonesResponse = await _supabase
            .from('milestones')
            .select('stat_id')
            .limit(1000); // 충분히 큰 제한

        final skillIdsWithMilestones = (milestonesResponse as List)
            .map((item) => item['stat_id'] as String)
            .toSet(); // 중복 제거

      if (skillIdsWithMilestones.isEmpty) {
        return [];
      }

              // 마일스톤이 있는 스탯들만 가져오기
        final response = await _supabase
            .from('stats')
            .select()
            .inFilter('id', skillIdsWithMilestones.toList())
            .order('name');

      List<Stat> skills = (response as List)
          .map((skill) => Stat.fromJson(skill))
          .toList();

      // 검색 필터링 적용
      if (searchQuery != null && searchQuery.isNotEmpty) {
        skills = skills.where((skill) =>
            skill.name.toLowerCase().contains(searchQuery.toLowerCase())
        ).toList();
      }

      return skills;
    } catch (e) {
      rethrow;
    }
  }

  // 특정 스탯의 마일스톤 가져오기
  Future<List<Milestone>> getMilestones(String skillId) async {
    try {
      final response = await _supabase
          .from('milestones')
          .select()
          .eq('stat_id', skillId)
          .order('level');

      return (response as List)
          .map((milestone) => Milestone.fromJson(milestone))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // 사용자의 모든 스탯 진행상황 가져오기 (마일스톤이 있는 스탯만)
  Future<List<SkillProgress>> getUserSkillsProgress(String userId) async {
    try {
      // 먼저 마일스톤이 있는 스탯 ID들을 가져오기
      final milestonesResponse = await _supabase
          .from('milestones')
          .select('stat_id')
          .limit(1000);

      final skillIdsWithMilestones = (milestonesResponse as List)
          .map((item) => item['stat_id'] as String)
          .toSet();

      if (skillIdsWithMilestones.isEmpty) {
        return [];
      }

      // 마일스톤이 있는 스탯들의 진행상황만 가져오기
      final response = await _supabase
          .rpc('get_user_all_stats_progress', params: {'p_user_id': userId});

      List<SkillProgress> skillsProgress = (response as List)
          .map((progress) => SkillProgress.fromJson(progress))
          .toList();

      // 마일스톤이 있는 스탯만 필터링
      skillsProgress = skillsProgress
          .where((progress) => skillIdsWithMilestones.contains(progress.skillId))
          .toList();

      // 각 스탯에 대한 추가 정보 로드
      for (int i = 0; i < skillsProgress.length; i++) {
        final skill = skillsProgress[i];
        
        // 목표 정보 로드
        final goal = await getStatGoal(userId, skill.skillId);
        if (goal != null) {
          skillsProgress[i] = SkillProgress(
            skillId: skill.skillId,
            skillName: skill.skillName,
            completedCount: skill.completedCount,
            totalCount: skill.totalCount,
            rank: skill.rank,
            lastCompletedAt: skill.lastCompletedAt,
            targetLevel: goal.targetLevel,
            targetDate: goal.targetDate,
            currentStreak: skill.currentStreak,
            bestStreak: skill.bestStreak,
            growthHistory: skill.growthHistory,
          );
        }

        // 성장 히스토리 로드
        final growthHistory = await getStatGrowthHistory(userId, skill.skillId);
        if (growthHistory.isNotEmpty) {
          skillsProgress[i] = SkillProgress(
            skillId: skill.skillId,
            skillName: skill.skillName,
            completedCount: skill.completedCount,
            totalCount: skill.totalCount,
            rank: skill.rank,
            lastCompletedAt: skill.lastCompletedAt,
            targetLevel: skillsProgress[i].targetLevel,
            targetDate: skillsProgress[i].targetDate,
            currentStreak: skill.currentStreak,
            bestStreak: skill.bestStreak,
            growthHistory: growthHistory,
          );
        }
      }

      return skillsProgress;
    } catch (e) {
      rethrow;
    }
  }

  // 특정 스탯의 진행상황 가져오기
  Future<SkillProgress?> getUserSkillProgress(String userId, String skillId) async {
    try {
      final response = await _supabase
          .rpc('get_user_stat_progress', params: {
            'p_user_id': userId,
            'p_stat_id': skillId,
          });

      if (response.isEmpty) return null;

      final progress = SkillProgress.fromJson(response.first);
      return progress;
    } catch (e) {
      return null;
    }
  }

  // 사용자의 완료된 마일스톤 가져오기
  Future<List<UserMilestone>> getUserMilestones(String userId, {String? skillId}) async {
    try {
      var query = _supabase
          .from('user_milestones')
          .select('*, milestones(*)')
          .eq('user_id', userId);

      if (skillId != null) {
        query = query.eq('milestones.stat_id', skillId);
      }

      final response = await query.order('completed_at', ascending: false);

      return (response as List)
          .map((userMilestone) => UserMilestone.fromJson(userMilestone))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // 마일스톤 완료
  Future<void> completeMilestone(String userId, String milestoneId) async {
    try {
      await _supabase
          .rpc('complete_milestone', params: {
        'p_user_id': userId,
        'p_milestone_id': milestoneId,
      });
    } catch (e) {
      rethrow;
    }
  }

  // 마일스톤 완료 취소
  Future<void> uncompleteMilestone(String userId, String milestoneId) async {
    try {
      await _supabase
          .rpc('uncomplete_milestone', params: {
        'p_user_id': userId,
        'p_milestone_id': milestoneId,
      });
    } catch (e) {
      rethrow;
    }
  }

  // 특정 스탯의 완료된 마일스톤 ID 목록 가져오기
  Future<Set<String>> getCompletedMilestoneIds(String userId, String skillId) async {
    try {
      final response = await _supabase
          .rpc('get_completed_milestone_ids', params: {
        'p_user_id': userId,
        'p_stat_id': skillId,
      });

      final completedIds = (response as List)
          .map((item) => item['milestone_id'] as String)
          .toSet();
      
      return completedIds;
    } catch (e) {
      return <String>{};
    }
  }

  // 상위 스탯 3개 가져오기 (랭크 기준)
  Future<List<SkillProgress>> getTopSkills(String userId) async {
    try {
      final response = await _supabase
          .rpc('get_top_stats', params: {
        'p_user_id': userId,
        'p_limit': 3,
      });

      return (response as List)
          .map((progress) => SkillProgress.fromJson(progress))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // 최근 성장한 스탯 3개 가져오기
  Future<List<SkillProgress>> getRecentlyGrownSkills(String userId) async {
    try {
      final response = await _supabase
          .rpc('get_recently_grown_stats', params: {
        'p_user_id': userId,
        'p_limit': 3,
      });

      return (response as List)
          .map((progress) => SkillProgress.fromJson(progress))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // 스탯 목표 설정
  Future<StatGoal> setStatGoal({
    required String userId,
    required String statId,
    required int targetLevel,
    required DateTime targetDate,
    String? description,
  }) async {
    try {
      final response = await _supabase
          .from('stat_goals')
          .upsert({
            'user_id': userId,
            'stat_id': statId,
            'target_level': targetLevel,
            'target_date': targetDate.toIso8601String(),
            'description': description,
            'is_completed': false,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return StatGoal.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // 스탯 목표 가져오기
  Future<StatGoal?> getStatGoal(String userId, String statId) async {
    try {
      final response = await _supabase
          .from('stat_goals')
          .select()
          .eq('user_id', userId)
          .eq('stat_id', statId)
          .maybeSingle();

      if (response == null) return null;
      return StatGoal.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // 스탯 목표 삭제
  Future<void> deleteStatGoal(String goalId) async {
    try {
      await _supabase
          .from('stat_goals')
          .delete()
          .eq('id', goalId);
    } catch (e) {
      rethrow;
    }
  }

  // 스탯 성장 히스토리 가져오기
  Future<List<StatGrowthRecord>> getStatGrowthHistory(String userId, String statId) async {
    try {
      final response = await _supabase
          .from('stat_growth_history')
          .select()
          .eq('user_id', userId)
          .eq('stat_id', statId)
          .order('achieved_at', ascending: false)
          .limit(50);

      return (response as List)
          .map((record) => StatGrowthRecord.fromJson(record))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // 성장 기록 추가
  Future<StatGrowthRecord> addGrowthRecord({
    required String userId,
    required String statId,
    required int level,
    required String rank,
    String? milestoneDescription,
  }) async {
    try {
      final response = await _supabase
          .from('stat_growth_history')
          .insert({
            'user_id': userId,
            'stat_id': statId,
            'level': level,
            'rank': rank,
            'achieved_at': DateTime.now().toIso8601String(),
            'milestone_description': milestoneDescription,
          })
          .select()
          .single();

      return StatGrowthRecord.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // 성과 통계 가져오기
  Future<List<StatPerformance>> getStatPerformance(String userId) async {
    try {
      // 임시로 빈 리스트 반환 (데이터베이스 함수가 아직 생성되지 않음)
      return [];
      
      // final response = await _supabase
      //     .rpc('get_stat_performance', params: {'p_user_id': userId});

      // return (response as List)
      //     .map((performance) => StatPerformance.fromJson(performance))
      //         .toList();
    } catch (e) {
      return [];
    }
  }

  // 성취 배지 가져오기
  Future<List<Achievement>> getUserAchievements(String userId) async {
    try {
      final response = await _supabase
          .from('user_achievements')
          .select('*, achievements(*)')
          .eq('user_id', userId)
          .order('unlocked_at', ascending: false);

      return (response as List)
          .map((item) => Achievement.fromJson({
            ...item['achievements'],
            'unlocked_at': item['unlocked_at'],
          }))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // 성취 배지 해금
  Future<void> unlockAchievement(String userId, String achievementId) async {
    try {
      await _supabase
          .from('user_achievements')
          .upsert({
            'user_id': userId,
            'achievement_id': achievementId,
            'unlocked_at': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      rethrow;
    }
  }

  // 스트릭 업데이트
  Future<void> updateStreak(String userId, String statId, int currentStreak, int bestStreak) async {
    try {
      await _supabase
          .from('user_stat_streaks')
          .upsert({
            'user_id': userId,
            'stat_id': statId,
            'current_streak': currentStreak,
            'best_streak': bestStreak,
            'updated_at': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      rethrow;
    }
  }

  // 스트릭 정보 가져오기
  Future<Map<String, int>> getStreakInfo(String userId, String statId) async {
    try {
      final response = await _supabase
          .from('user_stat_streaks')
          .select()
          .eq('user_id', userId)
          .eq('stat_id', statId)
          .maybeSingle();

      if (response == null) {
        return {'current': 0, 'best': 0};
      }

      return {
        'current': response['current_streak'] ?? 0,
        'best': response['best_streak'] ?? 0,
      };
    } catch (e) {
      return {'current': 0, 'best': 0};
    }
  }

  int _getRankOrder(String rank) {
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
}
