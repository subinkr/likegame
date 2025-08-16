import 'package:flutter/material.dart';

class UserProfile {
  final String id;
  final String email;
  final String nickname;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  UserProfile({
    required this.id,
    required this.email,
    required this.nickname,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      email: json['email'],
      nickname: json['nickname'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isDeleted: json['is_deleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nickname': nickname,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }
}

class Stat {
  final String id;
  final String name;
  final String key;
  final DateTime createdAt;

  Stat({
    required this.id,
    required this.name,
    required this.key,
    required this.createdAt,
  });

  factory Stat.fromJson(Map<String, dynamic> json) {
    return Stat(
      id: json['id'],
      name: json['name'],
      key: json['key'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class Milestone {
  final String id;
  final String statId; // stat_id로 통일
  final int level;
  final String description;
  final DateTime createdAt;

  Milestone({
    required this.id,
    required this.statId,
    required this.level,
    required this.description,
    required this.createdAt,
  });

  factory Milestone.fromJson(Map<String, dynamic> json) {
    return Milestone(
      id: json['id'],
      statId: json['stat_id'] ?? json['skill_id'], // 새로운 컬럼명과 기존 컬럼명 모두 지원
      level: json['level'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class UserMilestone {
  final String id;
  final String userId;
  final String milestoneId;
  final DateTime completedAt;
  final Milestone? milestone;

  UserMilestone({
    required this.id,
    required this.userId,
    required this.milestoneId,
    required this.completedAt,
    this.milestone,
  });

  factory UserMilestone.fromJson(Map<String, dynamic> json) {
    return UserMilestone(
      id: json['id'],
      userId: json['user_id'],
      milestoneId: json['milestone_id'],
      completedAt: DateTime.parse(json['completed_at']),
      milestone: json['milestones'] != null 
          ? Milestone.fromJson(json['milestones'])
          : null,
    );
  }
}

class SkillProgress {
  final String skillId;
  final String skillName;
  final int completedCount;
  final int totalCount;
  final String rank;
  final DateTime? lastCompletedAt;

  SkillProgress({
    required this.skillId,
    required this.skillName,
    required this.completedCount,
    required this.totalCount,
    required this.rank,
    this.lastCompletedAt,
  });

  factory SkillProgress.fromJson(Map<String, dynamic> json) {
    return SkillProgress(
      skillId: json['stat_id'] ?? json['skill_id'], // 새로운 함수와 기존 함수 모두 지원
      skillName: json['stat_name'] ?? json['skill_name'], // 새로운 함수와 기존 함수 모두 지원
      completedCount: json['completed_count'],
      totalCount: json['total_count'],
      rank: json['rank'],
      lastCompletedAt: json['last_completed_at'] != null 
          ? DateTime.parse(json['last_completed_at'])
          : null,
    );
  }

  double get progressPercentage {
    if (totalCount == 0) return 0.0;
    return completedCount / totalCount;
  }

  String get rankProgressText {
    final currentRankProgress = completedCount % 20;
    final nextRankThreshold = ((completedCount ~/ 20) + 1) * 20;
    return '$currentRankProgress/20';
  }
}

enum SkillRank {
  f('F', 0, 19),
  e('E', 20, 39),
  d('D', 40, 59),
  c('C', 60, 79),
  b('B', 80, 99),
  a('A', 100, 999);

  const SkillRank(this.name, this.minLevel, this.maxLevel);

  final String name;
  final int minLevel;
  final int maxLevel;

  static SkillRank fromCompletedCount(int completedCount) {
    if (completedCount < 20) return SkillRank.f;
    if (completedCount <= 39) return SkillRank.e;
    if (completedCount <= 59) return SkillRank.d;
    if (completedCount <= 79) return SkillRank.c;
    if (completedCount <= 99) return SkillRank.b;
    return SkillRank.a;
  }
}

class Skill {
  final String id;
  final String userId;
  final String name;
  final DateTime issueDate;
  final DateTime? expiryDate;
  final DateTime createdAt;

  Skill({
    required this.id,
    required this.userId,
    required this.name,
    required this.issueDate,
    this.expiryDate,
    required this.createdAt,
  });

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      issueDate: DateTime.parse(json['issue_date']),
      expiryDate: json['expiry_date'] != null 
          ? DateTime.parse(json['expiry_date']) 
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'issue_date': issueDate.toIso8601String(),
      'expiry_date': expiryDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class UserStatPriority {
  final String id;
  final String userId;
  final String statId;
  final int priorityOrder; // 순서 (낮을수록 높은 우선순위)
  final DateTime createdAt;
  final DateTime updatedAt;

  UserStatPriority({
    required this.id,
    required this.userId,
    required this.statId,
    required this.priorityOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserStatPriority.fromJson(Map<String, dynamic> json) {
    return UserStatPriority(
      id: json['id'],
      userId: json['user_id'],
      statId: json['stat_id'],
      priorityOrder: json['priority_order'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'stat_id': statId,
      'priority_order': priorityOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class Quest {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String? statId;
  final DateTime? dueDate;
  final String priority; // 'low', 'normal', 'high', 'highest'
  final String difficulty; // 'F', 'E', 'D', 'C', 'B', 'A'
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // 새로운 프리미엄 기능들
  final String? category;
  final List<String> tags;
  final List<SubTask> subTasks;
  final String? repeatPattern; // 'daily', 'weekly', 'monthly', 'yearly', 'custom'
  final Map<String, dynamic>? repeatConfig;
  final int estimatedMinutes;
  final int actualMinutes;
  final DateTime? startedAt;
  final DateTime? pausedAt;
  final List<TimeEntry> timeEntries;
  final String? templateId;
  final Map<String, dynamic>? customFields;

  Quest({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.statId,
    this.dueDate,
    required this.priority,
    this.difficulty = 'F',
    required this.isCompleted,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.category,
    this.tags = const [],
    this.subTasks = const [],
    this.repeatPattern,
    this.repeatConfig,
    this.estimatedMinutes = 0,
    this.actualMinutes = 0,
    this.startedAt,
    this.pausedAt,
    this.timeEntries = const [],
    this.templateId,
    this.customFields,
  });

  factory Quest.fromJson(Map<String, dynamic> json) {
    return Quest(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      description: json['description'],
      statId: json['stat_id'],
      dueDate: json['due_date'] != null 
          ? DateTime.parse(json['due_date']) 
          : null,
      priority: json['priority'] ?? 'normal',
      difficulty: json['difficulty'] ?? 'F',
      isCompleted: json['is_completed'],
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at']) 
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      category: json['category'],
      tags: List<String>.from(json['tags'] ?? []),
      subTasks: (json['sub_tasks'] as List<dynamic>? ?? [])
          .map((task) => SubTask.fromJson(task))
          .toList(),
      repeatPattern: json['repeat_pattern'],
      repeatConfig: json['repeat_config'] != null 
          ? Map<String, dynamic>.from(json['repeat_config'])
          : null,
      estimatedMinutes: json['estimated_minutes'] ?? 0,
      actualMinutes: json['actual_minutes'] ?? 0,
      startedAt: json['started_at'] != null 
          ? DateTime.parse(json['started_at']) 
          : null,
      pausedAt: json['paused_at'] != null 
          ? DateTime.parse(json['paused_at']) 
          : null,
      timeEntries: (json['time_entries'] as List<dynamic>? ?? [])
          .map((entry) => TimeEntry.fromJson(entry))
          .toList(),
      templateId: json['template_id'],
      customFields: json['custom_fields'] != null 
          ? Map<String, dynamic>.from(json['custom_fields'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'stat_id': statId,
      'due_date': dueDate?.toIso8601String(),
      'priority': priority,
      'difficulty': difficulty,
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'category': category,
      'tags': tags,
      'sub_tasks': subTasks.map((task) => task.toJson()).toList(),
      'repeat_pattern': repeatPattern,
      'repeat_config': repeatConfig,
      'estimated_minutes': estimatedMinutes,
      'actual_minutes': actualMinutes,
      'started_at': startedAt?.toIso8601String(),
      'paused_at': pausedAt?.toIso8601String(),
      'time_entries': timeEntries.map((entry) => entry.toJson()).toList(),
      'template_id': templateId,
      'custom_fields': customFields,
    };
  }

  String get priorityText {
    switch (priority) {
      case 'low':
        return '낮음';
      case 'normal':
        return '보통';
      case 'high':
        return '높음';
      case 'highest':
        return '긴급';
      default:
        return '보통';
    }
  }

  String get difficultyText {
    switch (difficulty) {
      case 'F':
        return 'F';
      case 'E':
        return 'E';
      case 'D':
        return 'D';
      case 'C':
        return 'C';
      case 'B':
        return 'B';
      case 'A':
        return 'A';
      default:
        return 'F';
    }
  }

  Color get priorityColor {
    switch (priority) {
      case 'low':
        return Colors.grey;
      case 'normal':
        return Colors.green;
      case 'high':
        return Colors.orange;
      case 'highest':
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  Color get difficultyColor {
    switch (difficulty) {
      case 'F':
        return Colors.grey[400]!;
      case 'E':
        return Colors.grey[600]!;
      case 'D':
        return Colors.blue[400]!;
      case 'C':
        return Colors.green[400]!;
      case 'B':
        return Colors.orange[400]!;
      case 'A':
        return Colors.red[400]!;
      default:
        return Colors.grey[400]!;
    }
  }

  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  String get dueDateText {
    if (dueDate == null) return '마감일 없음';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    
    if (due.isBefore(today)) {
      return '기한 초과';
    } else if (due.isAtSameMomentAs(today)) {
      return '오늘';
    } else if (due.isAtSameMomentAs(today.add(const Duration(days: 1)))) {
      return '내일';
    } else {
      return '${dueDate!.month}월 ${dueDate!.day}일';
    }
  }

  // 새로운 getter들
  double get progressPercentage {
    if (subTasks.isEmpty) {
      return isCompleted ? 1.0 : 0.0;
    }
    final completedCount = subTasks.where((task) => task.isCompleted).length;
    return completedCount / subTasks.length;
  }

  bool get isInProgress => startedAt != null && pausedAt == null && !isCompleted;

  String get timeSpentText {
    final totalMinutes = actualMinutes;
    if (totalMinutes < 60) {
      return '${totalMinutes}분';
    } else {
      final hours = totalMinutes ~/ 60;
      final minutes = totalMinutes % 60;
      return minutes > 0 ? '${hours}시간 ${minutes}분' : '${hours}시간';
    }
  }

  String get estimatedTimeText {
    if (estimatedMinutes == 0) return '예상 시간 없음';
    if (estimatedMinutes < 60) {
      return '${estimatedMinutes}분';
    } else {
      final hours = estimatedMinutes ~/ 60;
      final minutes = estimatedMinutes % 60;
      return minutes > 0 ? '${hours}시간 ${minutes}분' : '${hours}시간';
    }
  }
}

// 서브태스크 모델
class SubTask {
  final String id;
  final String title;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;

  SubTask({
    required this.id,
    required this.title,
    required this.isCompleted,
    this.completedAt,
    required this.createdAt,
  });

  factory SubTask.fromJson(Map<String, dynamic> json) {
    return SubTask(
      id: json['id'],
      title: json['title'],
      isCompleted: json['is_completed'] ?? false,
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at']) 
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// 시간 추적 엔트리 모델
class TimeEntry {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final String? note;

  TimeEntry({
    required this.id,
    required this.startTime,
    this.endTime,
    this.note,
  });

  factory TimeEntry.fromJson(Map<String, dynamic> json) {
    return TimeEntry(
      id: json['id'],
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null 
          ? DateTime.parse(json['end_time']) 
          : null,
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'note': note,
    };
  }

  int get durationMinutes {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime).inMinutes;
  }
}

// 퀘스트 템플릿 모델
class QuestTemplate {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String? category;
  final List<String> tags;
  final List<String> subTaskTitles;
  final String priority;
  final int estimatedMinutes;
  final String? repeatPattern;
  final Map<String, dynamic>? repeatConfig;
  final DateTime createdAt;

  QuestTemplate({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.category,
    this.tags = const [],
    this.subTaskTitles = const [],
    required this.priority,
    this.estimatedMinutes = 0,
    this.repeatPattern,
    this.repeatConfig,
    required this.createdAt,
  });

  factory QuestTemplate.fromJson(Map<String, dynamic> json) {
    return QuestTemplate(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      tags: List<String>.from(json['tags'] ?? []),
      subTaskTitles: List<String>.from(json['sub_task_titles'] ?? []),
      priority: json['priority'] ?? 'normal',
      estimatedMinutes: json['estimated_minutes'] ?? 0,
      repeatPattern: json['repeat_pattern'],
      repeatConfig: json['repeat_config'] != null 
          ? Map<String, dynamic>.from(json['repeat_config'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'category': category,
      'tags': tags,
      'sub_task_titles': subTaskTitles,
      'priority': priority,
      'estimated_minutes': estimatedMinutes,
      'repeat_pattern': repeatPattern,
      'repeat_config': repeatConfig,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
