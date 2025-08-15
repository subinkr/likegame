import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../config/supabase_config.dart';

class SkillService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 사용자의 스킬 목록 가져오기
  Future<List<Skill>> getUserSkills(String userId) async {
    try {
      final response = await _supabase
          .from('skills')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((skill) => Skill.fromJson(skill))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // 스킬 추가
  Future<Skill> addSkill({
    required String userId,
    required String name,
    required DateTime issueDate,
    DateTime? expiryDate,
  }) async {
    try {
      final response = await _supabase
          .from('skills')
          .insert({
            'user_id': userId,
            'name': name,
            'issue_date': issueDate.toIso8601String(),
            'expiry_date': expiryDate?.toIso8601String(),
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return Skill.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // 스킬 수정
  Future<Skill> updateSkill({
    required String skillId,
    required String name,
    required DateTime issueDate,
    DateTime? expiryDate,
  }) async {
    try {
      final response = await _supabase
          .from('skills')
          .update({
            'name': name,
            'issue_date': issueDate.toIso8601String(),
            'expiry_date': expiryDate?.toIso8601String(),
          })
          .eq('id', skillId)
          .select()
          .single();

      return Skill.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // 스킬 삭제
  Future<void> deleteSkill(String skillId) async {
    try {
      await _supabase
          .from('skills')
          .delete()
          .eq('id', skillId);
    } catch (e) {
      rethrow;
    }
  }


}
