import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class PriorityService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 사용자의 모든 스탯 우선순위 가져오기
  Future<List<UserStatPriority>> getUserStatPriorities(String userId) async {
    try {
      final response = await _supabase
          .from('user_stat_priorities')
          .select('*')
          .eq('user_id', userId)
          .order('priority_order', ascending: true);

      return (response as List)
          .map((priority) => UserStatPriority.fromJson(priority))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // 특정 스탯의 우선순위 가져오기
  Future<UserStatPriority?> getStatPriority(String userId, String statId) async {
    try {
      final response = await _supabase
          .from('user_stat_priorities')
          .select('*')
          .eq('user_id', userId)
          .eq('stat_id', statId)
          .maybeSingle();

      if (response != null) {
        return UserStatPriority.fromJson(response);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // 스탯 우선순위 설정/수정
  Future<UserStatPriority> setStatPriority({
    required String userId,
    required String statId,
    required int priorityOrder,
  }) async {
    try {
      // 기존 우선순위가 있으면 삭제
      await _supabase
          .from('user_stat_priorities')
          .delete()
          .eq('user_id', userId)
          .eq('stat_id', statId);

      // 새로운 우선순위 생성
      final response = await _supabase
          .from('user_stat_priorities')
          .insert({
            'user_id': userId,
            'stat_id': statId,
            'priority_order': priorityOrder,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return UserStatPriority.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // 스탯 우선순위 삭제
  Future<void> deleteStatPriority(String userId, String statId) async {
    try {
      await _supabase
          .from('user_stat_priorities')
          .delete()
          .eq('user_id', userId)
          .eq('stat_id', statId);
    } catch (e) {
      rethrow;
    }
  }

  // 우선순위별로 정렬된 스탯 목록 가져오기 (스탯 서비스와 연동)
  Future<List<Map<String, dynamic>>> getPrioritizedStats(String userId) async {
    try {
      final response = await _supabase.rpc('get_user_stats_with_priorities', params: {
        'p_user_id': userId,
      });

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      rethrow;
    }
  }
}
