import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'cache_service.dart';

class QuestService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final CacheService _cacheService = CacheService();
  
  static const Duration _cacheExpiry = Duration(minutes: 5);

  // 사용자의 모든 퀘스트 가져오기 (캐싱 적용)
  Future<List<Quest>> getUserQuests(String userId) async {
    final cacheKey = 'user_quests_$userId';
    
    // 캐시에서 먼저 확인
    final cachedData = await _cacheService.getData<List<dynamic>>(cacheKey);
    if (cachedData != null) {
      return cachedData.map((quest) => Quest.fromJson(quest)).toList();
    }

    try {
      final response = await _supabase
          .from('quests')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final quests = (response as List)
          .map((quest) => Quest.fromJson(quest))
          .toList();
      
      // 캐시에 저장
      await _cacheService.setData(cacheKey, response, expiry: _cacheExpiry);
      
      return quests;
    } catch (e) {
      rethrow;
    }
  }

  // 완료되지 않은 퀘스트만 가져오기 (캐싱 적용)
  Future<List<Quest>> getIncompleteQuests(String userId) async {
    final cacheKey = 'incomplete_quests_$userId';
    
    // 캐시에서 먼저 확인
    final cachedData = await _cacheService.getData<List<dynamic>>(cacheKey);
    if (cachedData != null) {
      return cachedData.map((quest) => Quest.fromJson(quest)).toList();
    }

    try {
      final response = await _supabase
          .from('quests')
          .select('*')
          .eq('user_id', userId)
          .eq('is_completed', false)
          .order('priority', ascending: false)
          .order('due_date', ascending: true);

      final quests = (response as List)
          .map((quest) => Quest.fromJson(quest))
          .toList();
      
      // 캐시에 저장
      await _cacheService.setData(cacheKey, response, expiry: _cacheExpiry);
      
      return quests;
    } catch (e) {
      rethrow;
    }
  }

  // 오늘 마감인 퀘스트 가져오기 (캐싱 적용)
  Future<List<Quest>> getTodayQuests(String userId) async {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final cacheKey = 'today_quests_${userId}_$todayStr';
    
    // 캐시에서 먼저 확인
    final cachedData = await _cacheService.getData<List<dynamic>>(cacheKey);
    if (cachedData != null) {
      return cachedData.map((quest) => Quest.fromJson(quest)).toList();
    }

    try {
      final response = await _supabase
          .from('quests')
          .select('*')
          .eq('user_id', userId)
          .eq('due_date', todayStr)
          .eq('is_completed', false)
          .order('priority', ascending: false);

      final quests = (response as List)
          .map((quest) => Quest.fromJson(quest))
          .toList();
      
      // 캐시에 저장 (오늘 데이터는 더 짧은 시간만 캐시)
      await _cacheService.setData(cacheKey, response, expiry: const Duration(minutes: 2));
      
      return quests;
    } catch (e) {
      rethrow;
    }
  }

  // 퀘스트 추가 (확장된 버전)
  Future<Quest> addQuest({
    required String userId,
    required String title,
    String? description,
    DateTime? dueDate,
    String priority = 'normal',
    String difficulty = 'F',
    String? category,
    List<SubTask> subTasks = const [],
    String? repeatPattern,
    Map<String, dynamic>? repeatConfig,
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

            'due_date': dueDate?.toIso8601String(),
            'priority': priority,
            'difficulty': difficulty,
            'category': category,
            'sub_tasks': subTasks.map((task) => task.toJson()).toList(),
            'repeat_pattern': repeatPattern,
            'repeat_config': repeatConfig,
            'template_id': templateId,
            'custom_fields': customFields,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final quest = Quest.fromJson(response);
      
      // 캐시 무효화
      await _invalidateUserCache(userId);
      
      return quest;
    } catch (e) {
      rethrow;
    }
  }

  // 퀘스트 수정
  Future<Quest> updateQuest({
    required String questId,
    String? title,
    String? description,
    DateTime? dueDate,
    String? priority,
    String? difficulty,
    bool? isCompleted,
    List<SubTask>? subTasks,
  }) async {
    try {
      // 먼저 현재 퀘스트 정보를 가져와서 사용자 ID 확인
      final currentQuestResponse = await _supabase
          .from('quests')
          .select('user_id')
          .eq('id', questId)
          .single();
      final userId = currentQuestResponse['user_id'] as String;

      final updateData = <String, dynamic>{};
      
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;

      if (dueDate != null) updateData['due_date'] = dueDate.toIso8601String();
      if (priority != null) updateData['priority'] = priority;
      if (difficulty != null) updateData['difficulty'] = difficulty;
      if (isCompleted != null) updateData['is_completed'] = isCompleted;
      
      updateData['updated_at'] = DateTime.now().toIso8601String();

      // 서브태스크가 제공된 경우 JSONB 형태로 변환하여 추가
      if (subTasks != null) {
        updateData['sub_tasks'] = subTasks.map((task) => {
          'id': task.id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : task.id,
          'title': task.title,
          'is_completed': task.isCompleted,
          'created_at': task.createdAt.toIso8601String(),
          if (task.completedAt != null) 'completed_at': task.completedAt!.toIso8601String(),
        }).toList();
      }

      // 퀘스트 업데이트
      final response = await _supabase
          .from('quests')
          .update(updateData)
          .eq('id', questId)
          .select()
          .single();

      final updatedQuest = Quest.fromJson(response);
      
      // 캐시 무효화
      await _invalidateUserCache(userId);
      
      return updatedQuest;
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

      final result = Quest.fromJson(response);
      
      // 캐시 무효화
      final questResponse = await _supabase
          .from('quests')
          .select('user_id')
          .eq('id', questId)
          .single();
      final userId = questResponse['user_id'] as String;
      await _invalidateUserCache(userId);
      
      return result;
    } catch (e) {
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

      final result = Quest.fromJson(response);
      
      // 캐시 무효화
      final questResponse = await _supabase
          .from('quests')
          .select('user_id')
          .eq('id', questId)
          .single();
      final userId = questResponse['user_id'] as String;
      await _invalidateUserCache(userId);
      
      return result;
    } catch (e) {
      rethrow;
    }
  }

  // 퀘스트 삭제
  Future<void> deleteQuest(String questId) async {
    try {
      // 삭제 전에 사용자 ID 가져오기
      final questResponse = await _supabase
          .from('quests')
          .select('user_id')
          .eq('id', questId)
          .single();
      final userId = questResponse['user_id'] as String;
      
      await _supabase
          .from('quests')
          .delete()
          .eq('id', questId);
      
      // 캐시 무효화
      await _invalidateUserCache(userId);
    } catch (e) {
      rethrow;
    }
  }







  // 서브태스크 추가 (완전히 새로 작성)
  Future<Quest> addSubTask(String questId, String title) async {
    try {
      // 1. 현재 퀘스트 정보 가져오기
      final currentQuest = await _supabase
          .from('quests')
          .select('*')
          .eq('id', questId)
          .single();
      
      final quest = Quest.fromJson(currentQuest);
      final subTasks = List<SubTask>.from(quest.subTasks);
      
      // 2. 고유 ID 생성 (UUID 스타일)
      final newId = '${DateTime.now().millisecondsSinceEpoch}_${(subTasks.length + 1)}';
      
      final newSubTask = SubTask(
        id: newId,
        title: title.trim(),
        isCompleted: false,
        createdAt: DateTime.now(),
      );
      
      subTasks.add(newSubTask);

      // 3. 서버 업데이트
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

  // 서브태스크 토글 (완전히 새로 작성)
  Future<Quest> toggleSubTask(String questId, String subTaskId) async {
    try {
      // 1. 현재 퀘스트 정보 가져오기
      final currentQuest = await _supabase
          .from('quests')
          .select('*')
          .eq('id', questId)
          .single();
      
      final quest = Quest.fromJson(currentQuest);
      
      // 2. 서브태스크 찾기 및 상태 변경
      final subTaskIndex = quest.subTasks.indexWhere((task) => task.id == subTaskId);
      if (subTaskIndex == -1) {
        throw Exception('서브태스크를 찾을 수 없습니다: $subTaskId');
      }
      
      final currentSubTask = quest.subTasks[subTaskIndex];
      final updatedSubTask = SubTask(
        id: currentSubTask.id,
        title: currentSubTask.title,
        isCompleted: !currentSubTask.isCompleted,
        completedAt: !currentSubTask.isCompleted ? DateTime.now() : null,
        createdAt: currentSubTask.createdAt,
      );
      
      // 3. 서브태스크 리스트 업데이트
      final updatedSubTasks = List<SubTask>.from(quest.subTasks);
      updatedSubTasks[subTaskIndex] = updatedSubTask;
      
      // 4. 서버 업데이트
      final response = await _supabase
          .from('quests')
          .update({
            'sub_tasks': updatedSubTasks.map((task) => task.toJson()).toList(),
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

  // 서브태스크 삭제 (새로 추가)
  Future<Quest> deleteSubTask(String questId, String subTaskId) async {
    try {
      // 1. 현재 퀘스트 정보 가져오기
      final currentQuest = await _supabase
          .from('quests')
          .select('*')
          .eq('id', questId)
          .single();
      
      final quest = Quest.fromJson(currentQuest);
      
      // 2. 서브태스크 필터링
      final updatedSubTasks = quest.subTasks.where((task) => task.id != subTaskId).toList();
      
      // 3. 서버 업데이트
      final response = await _supabase
          .from('quests')
          .update({
            'sub_tasks': updatedSubTasks.map((task) => task.toJson()).toList(),
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

  // 서브태스크 수정 (새로 추가)
  Future<Quest> updateSubTask(String questId, String subTaskId, String newTitle) async {
    try {
      // 1. 현재 퀘스트 정보 가져오기
      final currentQuest = await _supabase
          .from('quests')
          .select('*')
          .eq('id', questId)
          .single();
      
      final quest = Quest.fromJson(currentQuest);
      
      // 2. 서브태스크 찾기 및 수정
      final subTaskIndex = quest.subTasks.indexWhere((task) => task.id == subTaskId);
      if (subTaskIndex == -1) {
        throw Exception('서브태스크를 찾을 수 없습니다: $subTaskId');
      }
      
      final currentSubTask = quest.subTasks[subTaskIndex];
      final updatedSubTask = SubTask(
        id: currentSubTask.id,
        title: newTitle.trim(),
        isCompleted: currentSubTask.isCompleted,
        completedAt: currentSubTask.completedAt,
        createdAt: currentSubTask.createdAt,
      );
      
      // 3. 서브태스크 리스트 업데이트
      final updatedSubTasks = List<SubTask>.from(quest.subTasks);
      updatedSubTasks[subTaskIndex] = updatedSubTask;
      
      // 4. 서버 업데이트
      final response = await _supabase
          .from('quests')
          .update({
            'sub_tasks': updatedSubTasks.map((task) => task.toJson()).toList(),
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

  // 서브태스크 순서 변경 (새로 추가)
  Future<Quest> reorderSubTasks(String questId, List<String> newOrder) async {
    try {
      // 1. 현재 퀘스트 정보 가져오기
      final currentQuest = await _supabase
          .from('quests')
          .select('*')
          .eq('id', questId)
          .single();
      
      final quest = Quest.fromJson(currentQuest);
      
      // 2. 새로운 순서로 서브태스크 재배열
      final Map<String, SubTask> taskMap = {
        for (var task in quest.subTasks) task.id: task
      };
      
      final reorderedSubTasks = newOrder
          .where((id) => taskMap.containsKey(id))
          .map((id) => taskMap[id]!)
          .toList();
      
      // 3. 서버 업데이트
      final response = await _supabase
          .from('quests')
          .update({
            'sub_tasks': reorderedSubTasks.map((task) => task.toJson()).toList(),
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



  // 모든 서브태스크 완료/미완료 토글
  Future<Quest> toggleAllSubTasks(String questId, bool isCompleted) async {
    try {
      // 1. 현재 퀘스트 정보 가져오기
      final currentQuest = await _supabase
          .from('quests')
          .select('*')
          .eq('id', questId)
          .single();
      
      final quest = Quest.fromJson(currentQuest);
      
      // 2. 모든 서브태스크 상태 변경
      final updatedSubTasks = quest.subTasks.map((task) => SubTask(
        id: task.id,
        title: task.title,
        isCompleted: isCompleted,
        completedAt: isCompleted ? DateTime.now() : null,
        createdAt: task.createdAt,
      )).toList();
      
      // 3. 서버 업데이트 (updateQuest 메서드 사용)
      return await updateQuest(
        questId: questId,
        subTasks: updatedSubTasks,
      );
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
        subTasks: originalQuest.subTasks,
        priority: originalQuest.priority,
        difficulty: originalQuest.difficulty,
        repeatPattern: originalQuest.repeatPattern,
        repeatConfig: originalQuest.repeatConfig,
      );
    } catch (e) {
      rethrow;
    }
  }

  // 템플릿에서 퀘스트 생성
  Future<Quest> createQuestFromTemplate({
    required String userId,
    required QuestTemplate template,
    DateTime? dueDate,
    String priority = 'normal',
  }) async {
    try {
      final createdQuest = await addQuest(
        userId: userId,
        title: template.title,
        description: template.description,
        category: template.category,
        subTasks: template.subTasks,
        difficulty: template.difficulty,
        repeatPattern: template.repeatPattern,
        repeatConfig: template.repeatConfig,
        dueDate: dueDate,
        priority: priority,
        templateId: template.id,
      );
      
      return createdQuest;
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

      Map<String, int> categoryStats = {};

      for (final quest in allQuests) {
        if (quest.category != null) {
          categoryStats[quest.category!] = (categoryStats[quest.category!] ?? 0) + 1;
        }
      }

      return {
        'totalQuests': allQuests.length,
        'completedQuests': allQuests.where((q) => q.isCompleted).length,
        'overdueQuests': allQuests.where((q) => q.isOverdue).length,
        'completionRate': allQuests.isEmpty ? 0.0 : allQuests.where((q) => q.isCompleted).length / allQuests.length,
        'categoryStats': categoryStats,

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

  // 캐시 무효화
  Future<void> _invalidateUserCache(String userId) async {
    await _cacheService.removeData('user_quests_$userId');
    await _cacheService.removeData('incomplete_quests_$userId');
    
    // 오늘 날짜의 캐시도 무효화
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    await _cacheService.removeData('today_quests_${userId}_$todayStr');
  }
}
