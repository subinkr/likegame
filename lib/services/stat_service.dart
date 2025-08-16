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
      final response = await _supabase
          .rpc('get_stat_performance', params: {'p_user_id': userId});

      return (response as List)
          .map((performance) => StatPerformance.fromJson(performance))
          .toList();
    } catch (e) {
      // 데이터베이스 함수가 없으면 빈 리스트 반환
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

  // 마일스톤 완료 시 프리미엄 기능 처리
  Future<void> onMilestoneCompleted({
    required String userId,
    required String statId,
    required int level,
    required String rank,
    String? milestoneDescription,
  }) async {
    try {
      // 1. 성장 히스토리 추가
      await addGrowthRecord(
        userId: userId,
        statId: statId,
        level: level,
        rank: rank,
        milestoneDescription: milestoneDescription,
      );

      // 2. 성취 배지 확인 및 해금
      await checkAndUnlockAchievements(userId, statId);

      // 3. 스트릭 업데이트
      await updateStreakOnMilestone(userId, statId);
    } catch (e) {
      // 오류가 발생해도 기본 기능은 계속 작동하도록
      print('프리미엄 기능 처리 중 오류: $e');
    }
  }

  // 성취 배지 확인 및 해금
  Future<void> checkAndUnlockAchievements(String userId, String statId) async {
    try {
      // 총 마일스톤 완료 수 확인
      final totalCompleted = await getTotalMilestonesCompleted(userId);
      
      // 첫 번째 마일스톤 달성 배지
      if (totalCompleted == 1) {
        await unlockAchievement(userId, 'first_milestone');
      }
      
      // 마일스톤 개수별 배지
      if (totalCompleted == 10) {
        await unlockAchievement(userId, 'milestone_10');
      }
      if (totalCompleted == 50) {
        await unlockAchievement(userId, 'milestone_50');
      }
      if (totalCompleted == 100) {
        await unlockAchievement(userId, 'milestone_100');
      }

      // 랭크 업 배지 확인
      await checkRankUpAchievements(userId, statId);
    } catch (e) {
      print('성취 배지 확인 중 오류: $e');
    }
  }

  // 총 마일스톤 완료 수 가져오기
  Future<int> getTotalMilestonesCompleted(String userId) async {
    try {
      final response = await _supabase
          .from('user_milestones')
          .select('id')
          .eq('user_id', userId);
      
      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  // 랭크 업 배지 확인
  Future<void> checkRankUpAchievements(String userId, String statId) async {
    try {
      // 현재 스탯의 완료된 마일스톤 수 확인
      final completedCount = await getCompletedMilestonesCount(userId, statId);
      
      // 랭크별 배지 해금
      if (completedCount == 20) { // E랭크 달성
        await unlockAchievement(userId, 'rank_e');
      }
      if (completedCount == 40) { // D랭크 달성
        await unlockAchievement(userId, 'rank_d');
      }
      if (completedCount == 60) { // C랭크 달성
        await unlockAchievement(userId, 'rank_c');
      }
      if (completedCount == 80) { // B랭크 달성
        await unlockAchievement(userId, 'rank_b');
      }
      if (completedCount == 100) { // A랭크 달성
        await unlockAchievement(userId, 'rank_a');
      }
    } catch (e) {
      print('랭크 업 배지 확인 중 오류: $e');
    }
  }

  // 특정 스탯의 완료된 마일스톤 수 가져오기
  Future<int> getCompletedMilestonesCount(String userId, String statId) async {
    try {
      // 먼저 해당 스탯의 마일스톤 ID들을 가져오기
      final milestonesResponse = await _supabase
          .from('milestones')
          .select('id')
          .eq('stat_id', statId);
      
      final milestoneIds = (milestonesResponse as List)
          .map((m) => m['id'] as String)
          .toList();
      
      if (milestoneIds.isEmpty) return 0;
      
      // 해당 마일스톤들을 완료한 수 계산
      final response = await _supabase
          .from('user_milestones')
          .select('id')
          .eq('user_id', userId)
          .inFilter('milestone_id', milestoneIds);
      
      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  // 마일스톤 완료 시 스트릭 업데이트
  Future<void> updateStreakOnMilestone(String userId, String statId) async {
    try {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      
      // 어제 마일스톤 완료 여부 확인
      final yesterdayMilestones = await _supabase
          .from('user_milestones')
          .select('id')
          .eq('user_id', userId)
          .gte('completed_at', yesterday.toIso8601String())
          .lt('completed_at', today.toIso8601String());
      
      final currentStreakInfo = await getStreakInfo(userId, statId);
      int newCurrentStreak = currentStreakInfo['current'] ?? 0;
      int bestStreak = currentStreakInfo['best'] ?? 0;
      
      if (yesterdayMilestones.isNotEmpty) {
        // 연속 달성
        newCurrentStreak++;
        if (newCurrentStreak > bestStreak) {
          bestStreak = newCurrentStreak;
        }
      } else {
        // 연속 끊김, 새로 시작
        newCurrentStreak = 1;
      }
      
      // 스트릭 업데이트
      await updateStreak(userId, statId, newCurrentStreak, bestStreak);
      
      // 스트릭 배지 확인
      if (newCurrentStreak == 7) {
        await unlockAchievement(userId, 'streak_7');
      }
      if (newCurrentStreak == 30) {
        await unlockAchievement(userId, 'streak_30');
      }
    } catch (e) {
      print('스트릭 업데이트 중 오류: $e');
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
