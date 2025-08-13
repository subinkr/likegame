-- 랭크 시스템 수정: 실제 달성한 등급을 표시하도록 변경
-- F등급: 0개 완료
-- E등급: 20개 완료 (1-19개는 F등급)
-- D등급: 40개 완료 (20-39개는 E등급)
-- C등급: 60개 완료 (40-59개는 D등급)
-- B등급: 80개 완료 (60-79개는 C등급)
-- A등급: 100개 완료 (80-99개는 B등급)

-- get_user_skill_progress 함수 수정
CREATE OR REPLACE FUNCTION get_user_skill_progress(p_user_id UUID, p_skill_id UUID)
RETURNS TABLE (
  skill_id UUID,
  skill_name TEXT,
  category_name TEXT,
  completed_count INTEGER,
  total_count INTEGER,
  rank TEXT,
  last_completed_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    s.id as skill_id,
    s.name as skill_name,
    c.name as category_name,
    COALESCE(completed.count, 0)::INTEGER as completed_count,
    COALESCE(total.count, 0)::INTEGER as total_count,
    CASE 
      WHEN COALESCE(completed.count, 0) = 0 THEN 'F'
      WHEN COALESCE(completed.count, 0) BETWEEN 1 AND 19 THEN 'F'
      WHEN COALESCE(completed.count, 0) BETWEEN 20 AND 39 THEN 'E'
      WHEN COALESCE(completed.count, 0) BETWEEN 40 AND 59 THEN 'D'
      WHEN COALESCE(completed.count, 0) BETWEEN 60 AND 79 THEN 'C'
      WHEN COALESCE(completed.count, 0) BETWEEN 80 AND 99 THEN 'B'
      WHEN COALESCE(completed.count, 0) >= 100 THEN 'A'
    END as rank,
    completed.last_completed as last_completed_at
  FROM skills s
  JOIN categories c ON s.category_id = c.id
  LEFT JOIN (
    SELECT 
      m.skill_id,
      COUNT(*) as count,
      MAX(um.completed_at) as last_completed
    FROM user_milestones um
    JOIN milestones m ON um.milestone_id = m.id
    WHERE um.user_id = p_user_id
    GROUP BY m.skill_id
  ) completed ON s.id = completed.skill_id
  LEFT JOIN (
    SELECT m.skill_id, COUNT(*) as count
    FROM milestones m
    GROUP BY m.skill_id
  ) total ON s.id = total.skill_id
  WHERE s.id = p_skill_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- get_user_all_skills_progress 함수 수정
CREATE OR REPLACE FUNCTION get_user_all_skills_progress(p_user_id UUID)
RETURNS TABLE (
  skill_id UUID,
  skill_name TEXT,
  category_name TEXT,
  completed_count INTEGER,
  total_count INTEGER,
  rank TEXT,
  last_completed_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    s.id as skill_id,
    s.name as skill_name,
    c.name as category_name,
    COALESCE(completed.count, 0)::INTEGER as completed_count,
    COALESCE(total.count, 0)::INTEGER as total_count,
    CASE 
      WHEN COALESCE(completed.count, 0) = 0 THEN 'F'
      WHEN COALESCE(completed.count, 0) BETWEEN 1 AND 19 THEN 'F'
      WHEN COALESCE(completed.count, 0) BETWEEN 20 AND 39 THEN 'E'
      WHEN COALESCE(completed.count, 0) BETWEEN 40 AND 59 THEN 'D'
      WHEN COALESCE(completed.count, 0) BETWEEN 60 AND 79 THEN 'C'
      WHEN COALESCE(completed.count, 0) BETWEEN 80 AND 99 THEN 'B'
      WHEN COALESCE(completed.count, 0) >= 100 THEN 'A'
    END as rank,
    completed.last_completed as last_completed_at
  FROM skills s
  JOIN categories c ON s.category_id = c.id
  LEFT JOIN (
    SELECT 
      m.skill_id,
      COUNT(*) as count,
      MAX(um.completed_at) as last_completed
    FROM user_milestones um
    JOIN milestones m ON um.milestone_id = m.id
    WHERE um.user_id = p_user_id
    GROUP BY m.skill_id
  ) completed ON s.id = completed.skill_id
  LEFT JOIN (
    SELECT m.skill_id, COUNT(*) as count
    FROM milestones m
    GROUP BY m.skill_id
  ) total ON s.id = total.skill_id
  ORDER BY s.name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
