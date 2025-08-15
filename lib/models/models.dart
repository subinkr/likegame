import 'package:flutter/material.dart';

class UserProfile {
  final String id;
  final String email;
  final String nickname;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.nickname,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      email: json['email'],
      nickname: json['nickname'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nickname': nickname,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
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
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Quest({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.statId,
    this.dueDate,
    required this.priority,
    required this.isCompleted,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
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
      isCompleted: json['is_completed'],
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at']) 
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
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
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
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
}
