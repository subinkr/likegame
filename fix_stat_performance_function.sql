-- 수정된 성과 통계 함수
CREATE OR REPLACE FUNCTION get_stat_performance(p_user_id UUID)
RETURNS TABLE (
  stat_id UUID,
  stat_name TEXT,
  total_completed BIGINT,
  weekly_completed BIGINT,
  monthly_completed BIGINT,
  weekly_growth NUMERIC,
  monthly_growth NUMERIC,
  current_streak INTEGER,
  best_streak INTEGER,
  last_activity TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    s.id as stat_id,
    s.name as stat_name,
    COALESCE(um.total_completed, 0) as total_completed,
    COALESCE(um.weekly_completed, 0) as weekly_completed,
    COALESCE(um.monthly_completed, 0) as monthly_completed,
    COALESCE(um.weekly_growth, 0) as weekly_growth,
    COALESCE(um.monthly_growth, 0) as monthly_growth,
    COALESCE(uss.current_streak, 0) as current_streak,
    COALESCE(uss.best_streak, 0) as best_streak,
    uss.last_activity_date as last_activity
  FROM stats s
  LEFT JOIN (
    SELECT 
      m.stat_id,
      COUNT(*) as total_completed,
      COUNT(*) FILTER (WHERE um.completed_at >= NOW() - INTERVAL '7 days') as weekly_completed,
      COUNT(*) FILTER (WHERE um.completed_at >= NOW() - INTERVAL '30 days') as monthly_completed,
      CASE 
        WHEN COUNT(*) FILTER (WHERE um.completed_at >= NOW() - INTERVAL '14 days' AND um.completed_at < NOW() - INTERVAL '7 days') > 0 
        THEN ROUND(
          (COUNT(*) FILTER (WHERE um.completed_at >= NOW() - INTERVAL '7 days')::NUMERIC / 
           COUNT(*) FILTER (WHERE um.completed_at >= NOW() - INTERVAL '14 days' AND um.completed_at < NOW() - INTERVAL '7 days')) * 100, 2
        )
        ELSE 0
      END as weekly_growth,
      CASE 
        WHEN COUNT(*) FILTER (WHERE um.completed_at >= NOW() - INTERVAL '60 days' AND um.completed_at < NOW() - INTERVAL '30 days') > 0 
        THEN ROUND(
          (COUNT(*) FILTER (WHERE um.completed_at >= NOW() - INTERVAL '30 days')::NUMERIC / 
           COUNT(*) FILTER (WHERE um.completed_at >= NOW() - INTERVAL '60 days' AND um.completed_at < NOW() - INTERVAL '30 days')) * 100, 2
        )
        ELSE 0
      END as monthly_growth
    FROM user_milestones um
    JOIN milestones m ON um.milestone_id = m.id
    WHERE um.user_id = p_user_id
    GROUP BY m.stat_id
  ) um ON s.id = um.stat_id
  LEFT JOIN user_stat_streaks uss ON s.id = uss.stat_id AND uss.user_id = p_user_id
  WHERE um.total_completed > 0 OR uss.current_streak > 0
  ORDER BY um.total_completed DESC NULLS LAST;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
