-- 우선순위별로 정렬된 사용자 스탯을 가져오는 함수
CREATE OR REPLACE FUNCTION get_user_stats_with_priorities(user_id_param UUID)
RETURNS TABLE (
  stat_id UUID,
  stat_name TEXT,
  stat_key TEXT,
  completed_count BIGINT,
  total_count BIGINT,
  rank TEXT,
  priority INTEGER,
  priority_text TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    s.id as stat_id,
    s.name as stat_name,
    s.key as stat_key,
    COALESCE(um.completed_count, 0) as completed_count,
    COALESCE(m.total_count, 0) as total_count,
    CASE 
      WHEN COALESCE(um.completed_count, 0) < 20 THEN 'F'
      WHEN COALESCE(um.completed_count, 0) < 40 THEN 'E'
      WHEN COALESCE(um.completed_count, 0) < 60 THEN 'D'
      WHEN COALESCE(um.completed_count, 0) < 80 THEN 'C'
      WHEN COALESCE(um.completed_count, 0) < 100 THEN 'B'
      ELSE 'A'
    END as rank,
    COALESCE(usp.priority, 1) as priority,
    CASE 
      WHEN COALESCE(usp.priority, 1) = 0 THEN '낮음'
      WHEN COALESCE(usp.priority, 1) = 1 THEN '보통'
      WHEN COALESCE(usp.priority, 1) = 2 THEN '높음'
      WHEN COALESCE(usp.priority, 1) = 3 THEN '최고'
      ELSE '보통'
    END as priority_text
  FROM stats s
  LEFT JOIN (
    SELECT 
      stat_id,
      COUNT(*) as completed_count
    FROM user_milestones um
    JOIN milestones m ON um.milestone_id = m.id
    WHERE um.user_id = user_id_param
    GROUP BY stat_id
  ) um ON s.id = um.stat_id
  LEFT JOIN (
    SELECT 
      stat_id,
      COUNT(*) as total_count
    FROM milestones
    GROUP BY stat_id
  ) m ON s.id = m.stat_id
  LEFT JOIN user_stat_priorities usp ON s.id = usp.stat_id AND usp.user_id = user_id_param
  ORDER BY COALESCE(usp.priority, 1) DESC, s.name ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 함수에 대한 RLS 정책 설정
GRANT EXECUTE ON FUNCTION get_user_stats_with_priorities(UUID) TO authenticated;
