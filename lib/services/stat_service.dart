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

      List<SkillProgress> allProgress = (response as List)
          .map((progress) => SkillProgress.fromJson(progress))
          .toList();

      // 마일스톤이 있는 스탯만 필터링
      return allProgress.where((progress) => 
          skillIdsWithMilestones.contains(progress.skillId)
      ).toList();
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


}
