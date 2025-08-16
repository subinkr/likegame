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

  // 퀘스트 추가 (확장된 버전)
  Future<Quest> addQuest({
    required String userId,
    required String title,
    String? description,
    String? statId,
    DateTime? dueDate,
    String priority = 'normal',
    String difficulty = 'F',
    String? category,
    List<String> tags = const [],
    List<SubTask> subTasks = const [],
    String? repeatPattern,
    Map<String, dynamic>? repeatConfig,
    int estimatedMinutes = 0,
    String? templateId,
    Map<String, dynamic>? customFields,
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
            'difficulty': difficulty,
            'category': category,
            'tags': tags,
            'sub_tasks': subTasks.map((task) => task.toJson()).toList(),
            'repeat_pattern': repeatPattern,
            'repeat_config': repeatConfig,
            'estimated_minutes': estimatedMinutes,
            'actual_minutes': 0,
            'template_id': templateId,
            'custom_fields': customFields,
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
    String? difficulty,
    bool? isCompleted,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (statId != null) updateData['stat_id'] = statId;
      if (dueDate != null) updateData['due_date'] = dueDate.toIso8601String();
      if (priority != null) updateData['priority'] = priority;
      if (difficulty != null) updateData['difficulty'] = difficulty;
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
      final updateData = <String, dynamic>{
        'is_completed': isCompleted,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // 완료하는 경우 완료 시간 설정
      if (isCompleted) {
        updateData['completed_at'] = DateTime.now().toIso8601String();
      } else {
        // 미완료로 되돌리는 경우 완료 시간 제거
        updateData['completed_at'] = null;
      }

      final response = await _supabase
          .from('quests')
          .update(updateData)
          .eq('id', questId)
          .select()
          .single();

      return Quest.fromJson(response);
    } catch (e) {
      print('퀘스트 토글 실패: $e');
      rethrow;
    }
  }

  // 퀘스트 진행중 상태 토글
  Future<Quest> toggleQuestProgress(String questId) async {
    try {
      // 현재 퀘스트 상태 확인
      final currentQuest = await _supabase
          .from('quests')
          .select('*')
          .eq('id', questId)
          .single();
      
      final quest = Quest.fromJson(currentQuest);
      final isCurrentlyInProgress = quest.isInProgress;
      
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (isCurrentlyInProgress) {
        // 진행중이면 중지
        updateData['started_at'] = null;
      } else {
        // 진행중이 아니면 시작
        updateData['started_at'] = DateTime.now().toIso8601String();
      }

      final response = await _supabase
          .from('quests')
          .update(updateData)
          .eq('id', questId)
          .select()
          .single();

      return Quest.fromJson(response);
    } catch (e) {
      print('퀘스트 진행 상태 토글 실패: $e');
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







  // 서브태스크 추가
  Future<Quest> addSubTask(String questId, String title) async {
    try {
      final currentQuest = await _supabase
          .from('quests')
          .select('*')
          .eq('id', questId)
          .single();
      
      final quest = Quest.fromJson(currentQuest);
      final subTasks = List<SubTask>.from(quest.subTasks);
      
      final newSubTask = SubTask(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        isCompleted: false,
        createdAt: DateTime.now(),
      );
      
      subTasks.add(newSubTask);

      final response = await _supabase
          .from('quests')
          .update({
            'sub_tasks': subTasks.map((task) => task.toJson()).toList(),
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

  // 서브태스크 토글
  Future<Quest> toggleSubTask(String questId, String subTaskId) async {
    try {
      final currentQuest = await _supabase
          .from('quests')
          .select('*')
          .eq('id', questId)
          .single();
      
      final quest = Quest.fromJson(currentQuest);
      final subTasks = quest.subTasks.map((task) {
        if (task.id == subTaskId) {
          return SubTask(
            id: task.id,
            title: task.title,
            isCompleted: !task.isCompleted,
            completedAt: !task.isCompleted ? DateTime.now() : null,
            createdAt: task.createdAt,
          );
        }
        return task;
      }).toList();

      final response = await _supabase
          .from('quests')
          .update({
            'sub_tasks': subTasks.map((task) => task.toJson()).toList(),
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



  // 퀘스트 복제
  Future<Quest> duplicateQuest(String userId, Quest originalQuest) async {
    try {
      return await addQuest(
        userId: userId,
        title: '${originalQuest.title} (복사본)',
        description: originalQuest.description,
        category: originalQuest.category,
        tags: originalQuest.tags,
        subTasks: originalQuest.subTasks,
        priority: originalQuest.priority,
        difficulty: originalQuest.difficulty,
        estimatedMinutes: originalQuest.estimatedMinutes,
        repeatPattern: originalQuest.repeatPattern,
        repeatConfig: originalQuest.repeatConfig,
      );
    } catch (e) {
      rethrow;
    }
  }

  // 고급 통계
  Future<Map<String, dynamic>> getAdvancedStats(String userId) async {
    try {
      final allQuests = await getUserQuests(userId);
      final now = DateTime.now();
      final thisWeek = now.subtract(Duration(days: now.weekday - 1));
      final thisMonth = DateTime(now.year, now.month, 1);

      int totalTimeSpent = 0;
      int totalEstimatedTime = 0;
      Map<String, int> categoryStats = {};
      Map<String, int> tagStats = {};

      for (final quest in allQuests) {
        totalTimeSpent += quest.actualMinutes;
        totalEstimatedTime += quest.estimatedMinutes;
        
        if (quest.category != null) {
          categoryStats[quest.category!] = (categoryStats[quest.category!] ?? 0) + 1;
        }
        
        for (final tag in quest.tags) {
          tagStats[tag] = (tagStats[tag] ?? 0) + 1;
        }
      }

      return {
        'totalQuests': allQuests.length,
        'completedQuests': allQuests.where((q) => q.isCompleted).length,
        'overdueQuests': allQuests.where((q) => q.isOverdue).length,
        'totalTimeSpent': totalTimeSpent,
        'totalEstimatedTime': totalEstimatedTime,
        'completionRate': allQuests.isEmpty ? 0.0 : allQuests.where((q) => q.isCompleted).length / allQuests.length,
        'categoryStats': categoryStats,
        'tagStats': tagStats,
        'thisWeekQuests': allQuests.where((q) => 
            q.createdAt.isAfter(thisWeek) && q.createdAt.isBefore(thisWeek.add(const Duration(days: 7)))
        ).length,
        'thisMonthQuests': allQuests.where((q) => 
            q.createdAt.isAfter(thisMonth) && q.createdAt.isBefore(DateTime(now.year, now.month + 1, 1))
        ).length,
      };
    } catch (e) {
      rethrow;
    }
  }
}
