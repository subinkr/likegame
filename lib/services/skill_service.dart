import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class SkillService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 모든 카테고리 가져오기
  Future<List<Category>> getCategories() async {
    try {
      final response = await _supabase
          .from('categories')
          .select()
          .order('name');

      return (response as List)
          .map((category) => Category.fromJson(category))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // 모든 스킬 가져오기 (카테고리 포함)
  Future<List<Skill>> getSkills({String? categoryId, String? searchQuery}) async {
    try {
      var query = _supabase
          .from('skills')
          .select('*, categories(*)');

      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('name', '%$searchQuery%');
      }

      final response = await query.order('name');

      return (response as List)
          .map((skill) => Skill.fromJson(skill))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // 특정 스킬의 마일스톤 가져오기
  Future<List<Milestone>> getMilestones(String skillId) async {
    try {
      final response = await _supabase
          .from('milestones')
          .select()
          .eq('skill_id', skillId)
          .order('level');

      return (response as List)
          .map((milestone) => Milestone.fromJson(milestone))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // 사용자의 모든 스킬 진행상황 가져오기
  Future<List<SkillProgress>> getUserSkillsProgress(String userId) async {
    try {
      final response = await _supabase
          .rpc('get_user_all_skills_progress', params: {'p_user_id': userId});

      return (response as List)
          .map((progress) => SkillProgress.fromJson(progress))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // 특정 스킬의 진행상황 가져오기
  Future<SkillProgress?> getUserSkillProgress(String userId, String skillId) async {
    try {
      final response = await _supabase
          .rpc('get_user_skill_progress', params: {
            'p_user_id': userId,
            'p_skill_id': skillId,
          });

      if (response.isEmpty) return null;

      return SkillProgress.fromJson(response.first);
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
        query = query.eq('milestones.skill_id', skillId);
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
          .from('user_milestones')
          .insert({
            'user_id': userId,
            'milestone_id': milestoneId,
          });
    } catch (e) {
      rethrow;
    }
  }

  // 마일스톤 완료 취소
  Future<void> uncompleteMilestone(String userId, String milestoneId) async {
    try {
      await _supabase
          .from('user_milestones')
          .delete()
          .eq('user_id', userId)
          .eq('milestone_id', milestoneId);
    } catch (e) {
      rethrow;
    }
  }

  // 특정 스킬의 완료된 마일스톤 ID 목록 가져오기
  Future<Set<String>> getCompletedMilestoneIds(String userId, String skillId) async {
    try {
      final response = await _supabase
          .from('user_milestones')
          .select('milestone_id, milestones!inner(skill_id)')
          .eq('user_id', userId)
          .eq('milestones.skill_id', skillId);

      return (response as List)
          .map((item) => item['milestone_id'] as String)
          .toSet();
    } catch (e) {
      return <String>{};
    }
  }

  // 상위 스킬 3개 가져오기 (랭크 기준)
  Future<List<SkillProgress>> getTopSkills(String userId) async {
    try {
      final allProgress = await getUserSkillsProgress(userId);
      
      // 랭크별로 정렬하고, 같은 랭크면 완료된 마일스톤 수로 정렬
      allProgress.sort((a, b) {
        final rankComparison = _getRankOrder(b.rank).compareTo(_getRankOrder(a.rank));
        if (rankComparison != 0) return rankComparison;
        return b.completedCount.compareTo(a.completedCount);
      });

      return allProgress.take(3).toList();
    } catch (e) {
      return [];
    }
  }

  // 최근 성장한 스킬 3개 가져오기
  Future<List<SkillProgress>> getRecentlyGrownSkills(String userId) async {
    try {
      final allProgress = await getUserSkillsProgress(userId);
      
      // 최근 완료 시간이 있는 스킬들만 필터링하고 정렬
      final recentSkills = allProgress
          .where((progress) => progress.lastCompletedAt != null)
          .toList();
          
      recentSkills.sort((a, b) => 
          b.lastCompletedAt!.compareTo(a.lastCompletedAt!));

      return recentSkills.take(3).toList();
    } catch (e) {
      return [];
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
