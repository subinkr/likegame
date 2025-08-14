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

class Skill {
  final String id;
  final String name;
  final String key;
  final DateTime createdAt;

  Skill({
    required this.id,
    required this.name,
    required this.key,
    required this.createdAt,
  });

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      id: json['id'],
      name: json['name'],
      key: json['key'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class Milestone {
  final String id;
  final String skillId; // 내부적으로는 skillId로 유지하되, 데이터베이스에서는 stat_id를 사용
  final int level;
  final String description;
  final DateTime createdAt;

  Milestone({
    required this.id,
    required this.skillId,
    required this.level,
    required this.description,
    required this.createdAt,
  });

  factory Milestone.fromJson(Map<String, dynamic> json) {
    return Milestone(
      id: json['id'],
      skillId: json['stat_id'] ?? json['skill_id'], // 새로운 컬럼명과 기존 컬럼명 모두 지원
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
