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

class Category {
  final String id;
  final String name;
  final DateTime createdAt;

  Category({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class Skill {
  final String id;
  final String name;
  final String categoryId;
  final String key;
  final DateTime createdAt;
  final Category? category;

  Skill({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.key,
    required this.createdAt,
    this.category,
  });

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      id: json['id'],
      name: json['name'],
      categoryId: json['category_id'],
      key: json['key'],
      createdAt: DateTime.parse(json['created_at']),
      category: json['categories'] != null 
          ? Category.fromJson(json['categories'])
          : null,
    );
  }
}

class Milestone {
  final String id;
  final String skillId;
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
      skillId: json['skill_id'],
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
  final String categoryName;
  final int completedCount;
  final int totalCount;
  final String rank;
  final DateTime? lastCompletedAt;

  SkillProgress({
    required this.skillId,
    required this.skillName,
    required this.categoryName,
    required this.completedCount,
    required this.totalCount,
    required this.rank,
    this.lastCompletedAt,
  });

  factory SkillProgress.fromJson(Map<String, dynamic> json) {
    return SkillProgress(
      skillId: json['skill_id'],
      skillName: json['skill_name'],
      categoryName: json['category_name'],
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
  f('F', 0, 0),
  e('E', 1, 20),
  d('D', 21, 40),
  c('C', 41, 60),
  b('B', 61, 80),
  a('A', 81, 100);

  const SkillRank(this.name, this.minLevel, this.maxLevel);

  final String name;
  final int minLevel;
  final int maxLevel;

  static SkillRank fromCompletedCount(int completedCount) {
    if (completedCount == 0) return SkillRank.f;
    if (completedCount <= 20) return SkillRank.e;
    if (completedCount <= 40) return SkillRank.d;
    if (completedCount <= 60) return SkillRank.c;
    if (completedCount <= 80) return SkillRank.b;
    return SkillRank.a;
  }
}
