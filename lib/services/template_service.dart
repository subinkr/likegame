import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class TemplateService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 모든 템플릿 가져오기 (검색만 지원)
  Future<List<QuestTemplate>> getAllTemplates({
    String? searchQuery,
  }) async {
    try {
      var query = _supabase
          .from('quest_templates')
          .select('*');

      // 검색
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('title.ilike.%$searchQuery%,description.ilike.%$searchQuery%');
      }

      // 최신순으로 정렬
      final response = await query.order('created_at', ascending: false);
      return (response as List)
          .map((template) => QuestTemplate.fromJson(template))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // 템플릿 상세 정보 가져오기
  Future<QuestTemplate?> getTemplateById(String templateId) async {
    try {
      final response = await _supabase
          .from('quest_templates')
          .select('*')
          .eq('id', templateId)
          .single();

      return QuestTemplate.fromJson(response);
    } catch (e) {
      return null;
    }
  }


}
