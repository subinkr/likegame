import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class QuestService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 사용자의 모든 퀘스트 가져오기
  Future<List<Quest>> getUserQuests(String userId) async {
    try {
      final response = await _supabase
          .from('quests')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((quest) => Quest.fromJson(quest))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // 완료되지 않은 퀘스트만 가져오기
  Future<List<Quest>> getIncompleteQuests(String userId) async {
    try {
      final response = await _supabase
          .from('quests')
          .select('*')
          .eq('user_id', userId)
          .eq('is_completed', false)
          .order('priority', ascending: false)
          .order('due_date', ascending: true);

      return (response as List)
          .map((quest) => Quest.fromJson(quest))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // 오늘 마감인 퀘스트 가져오기
  Future<List<Quest>> getTodayQuests(String userId) async {
    try {
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      final response = await _supabase
          .from('quests')
          .select('*')
          .eq('user_id', userId)
          .eq('due_date', todayStr)
          .eq('is_completed', false)
          .order('priority', ascending: false);

      return (response as List)
          .map((quest) => Quest.fromJson(quest))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // 퀘스트 추가
  Future<Quest> addQuest({
    required String userId,
    required String title,
    String? description,
    String? statId,
    DateTime? dueDate,
    String priority = 'normal',
  }) async {
    try {
      final response = await _supabase
          .from('quests')
          .insert({
            'user_id': userId,
            'title': title,
            'description': description,
            'stat_id': statId,
            'due_date': dueDate?.toIso8601String(),
            'priority': priority,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return Quest.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // 퀘스트 수정
  Future<Quest> updateQuest({
    required String questId,
    String? title,
    String? description,
    String? statId,
    DateTime? dueDate,
    String? priority,
    bool? isCompleted,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (statId != null) updateData['stat_id'] = statId;
      if (dueDate != null) updateData['due_date'] = dueDate.toIso8601String();
      if (priority != null) updateData['priority'] = priority;
      if (isCompleted != null) updateData['is_completed'] = isCompleted;
      
      updateData['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('quests')
          .update(updateData)
          .eq('id', questId)
          .select()
          .single();

      return Quest.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // 퀘스트 완료/미완료 토글
  Future<Quest> toggleQuest(String questId, bool isCompleted) async {
    try {
      final response = await _supabase
          .from('quests')
          .update({
            'is_completed': isCompleted,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', questId)
          .select()
          .single();

      return Quest.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // 퀘스트 삭제
  Future<void> deleteQuest(String questId) async {
    try {
      await _supabase
          .from('quests')
          .delete()
          .eq('id', questId);
    } catch (e) {
      rethrow;
    }
  }

  // 스탯과 연결된 퀘스트 가져오기
  Future<List<Quest>> getQuestsByStat(String userId, String statId) async {
    try {
      final response = await _supabase
          .from('quests')
          .select('*')
          .eq('user_id', userId)
          .eq('stat_id', statId)
          .order('priority', ascending: false)
          .order('due_date', ascending: true);

      return (response as List)
          .map((quest) => Quest.fromJson(quest))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // 퀘스트 통계 가져오기
  Future<Map<String, int>> getQuestStats(String userId) async {
    try {
      final allQuests = await getUserQuests(userId);
      
      return {
        'total': allQuests.length,
        'completed': allQuests.where((quest) => quest.isCompleted).length,
        'incomplete': allQuests.where((quest) => !quest.isCompleted).length,
        'overdue': allQuests.where((quest) => quest.isOverdue).length,
        'today': allQuests.where((quest) => 
            quest.dueDate != null && 
            !quest.isCompleted &&
            quest.dueDate!.year == DateTime.now().year &&
            quest.dueDate!.month == DateTime.now().month &&
            quest.dueDate!.day == DateTime.now().day
        ).length,
      };
    } catch (e) {
      rethrow;
    }
  }
}
