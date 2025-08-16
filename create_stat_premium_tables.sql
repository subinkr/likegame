-- 스탯 프리미엄 기능을 위한 테이블들

-- 스탯 목표 테이블
CREATE TABLE IF NOT EXISTS stat_goals (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  stat_id UUID REFERENCES stats(id) ON DELETE CASCADE,
  target_level INTEGER NOT NULL CHECK (target_level > 0),
  target_date DATE NOT NULL,
  description TEXT,
  is_completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, stat_id)
);

-- 스탯 성장 히스토리 테이블
CREATE TABLE IF NOT EXISTS stat_growth_history (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  stat_id UUID REFERENCES stats(id) ON DELETE CASCADE,
  level INTEGER NOT NULL,
  rank TEXT NOT NULL,
  achieved_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  milestone_description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 스탯 스트릭 테이블
CREATE TABLE IF NOT EXISTS user_stat_streaks (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  stat_id UUID REFERENCES stats(id) ON DELETE CASCADE,
  current_streak INTEGER DEFAULT 0,
  best_streak INTEGER DEFAULT 0,
  last_activity_date DATE,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, stat_id)
);

-- 성취 배지 테이블
CREATE TABLE IF NOT EXISTS achievements (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  icon TEXT NOT NULL,
  category TEXT NOT NULL,
  required_value INTEGER NOT NULL,
  condition TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 사용자 성취 배지 테이블
CREATE TABLE IF NOT EXISTS user_achievements (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  achievement_id UUID REFERENCES achievements(id) ON DELETE CASCADE,
  unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, achievement_id)
);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_stat_goals_user_id ON stat_goals(user_id);
CREATE INDEX IF NOT EXISTS idx_stat_goals_stat_id ON stat_goals(stat_id);
CREATE INDEX IF NOT EXISTS idx_stat_growth_history_user_stat ON stat_growth_history(user_id, stat_id);
CREATE INDEX IF NOT EXISTS idx_stat_growth_history_achieved_at ON stat_growth_history(achieved_at);
CREATE INDEX IF NOT EXISTS idx_user_stat_streaks_user_stat ON user_stat_streaks(user_id, stat_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_user_id ON user_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_unlocked_at ON user_achievements(unlocked_at);

-- RLS 정책 설정
ALTER TABLE stat_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE stat_growth_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_stat_streaks ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;

-- stat_goals RLS 정책
CREATE POLICY "Users can view their own stat goals" ON stat_goals
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own stat goals" ON stat_goals
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own stat goals" ON stat_goals
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own stat goals" ON stat_goals
  FOR DELETE USING (auth.uid() = user_id);

-- stat_growth_history RLS 정책
CREATE POLICY "Users can view their own growth history" ON stat_growth_history
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own growth history" ON stat_growth_history
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- user_stat_streaks RLS 정책
CREATE POLICY "Users can view their own streaks" ON user_stat_streaks
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own streaks" ON user_stat_streaks
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own streaks" ON user_stat_streaks
  FOR UPDATE USING (auth.uid() = user_id);

-- user_achievements RLS 정책
CREATE POLICY "Users can view their own achievements" ON user_achievements
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own achievements" ON user_achievements
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 성과 통계를 위한 함수
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
      stat_id,
      COUNT(*) as total_completed,
      COUNT(*) FILTER (WHERE completed_at >= NOW() - INTERVAL '7 days') as weekly_completed,
      COUNT(*) FILTER (WHERE completed_at >= NOW() - INTERVAL '30 days') as monthly_completed,
      ROUND(
        (COUNT(*) FILTER (WHERE completed_at >= NOW() - INTERVAL '7 days')::NUMERIC / 
         NULLIF(COUNT(*) FILTER (WHERE completed_at >= NOW() - INTERVAL '14 days' AND completed_at < NOW() - INTERVAL '7 days'), 0)) * 100, 2
      ) as weekly_growth,
      ROUND(
        (COUNT(*) FILTER (WHERE completed_at >= NOW() - INTERVAL '30 days')::NUMERIC / 
         NULLIF(COUNT(*) FILTER (WHERE completed_at >= NOW() - INTERVAL '60 days' AND completed_at < NOW() - INTERVAL '30 days'), 0)) * 100, 2
      ) as monthly_growth
    FROM user_milestones
    WHERE user_id = p_user_id
    GROUP BY stat_id
  ) um ON s.id = um.stat_id
  LEFT JOIN user_stat_streaks uss ON s.id = uss.stat_id AND uss.user_id = p_user_id
  WHERE um.total_completed > 0 OR uss.current_streak > 0
  ORDER BY um.total_completed DESC NULLS LAST;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 기본 성취 배지 데이터 삽입
INSERT INTO achievements (name, description, icon, category, required_value, condition) VALUES
('첫 걸음', '첫 번째 마일스톤을 달성했습니다', '🎯', 'milestone', 1, 'first_milestone'),
('열정의 시작', '10개의 마일스톤을 달성했습니다', '🔥', 'milestone', 10, 'milestone_count'),
('성장하는 자', '50개의 마일스톤을 달성했습니다', '🌱', 'milestone', 50, 'milestone_count'),
('마스터', '100개의 마일스톤을 달성했습니다', '👑', 'milestone', 100, 'milestone_count'),
('연속 달성', '7일 연속으로 마일스톤을 달성했습니다', '🔥', 'streak', 7, 'daily_streak'),
('불굴의 의지', '30일 연속으로 마일스톤을 달성했습니다', '💪', 'streak', 30, 'daily_streak'),
('랭크 업', '첫 번째 랭크 업을 달성했습니다', '⭐', 'rank', 1, 'rank_up'),
('성장의 여정', '모든 랭크를 경험했습니다', '🌈', 'rank', 6, 'all_ranks'),
('목표 달성', '첫 번째 목표를 달성했습니다', '🎯', 'goal', 1, 'goal_completed'),
('계획적인 성장', '10개의 목표를 달성했습니다', '📈', 'goal', 10, 'goal_completed')
ON CONFLICT DO NOTHING;

-- 트리거 함수: 마일스톤 완료 시 성장 히스토리 자동 추가
CREATE OR REPLACE FUNCTION add_growth_record_on_milestone()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO stat_growth_history (user_id, stat_id, level, rank, milestone_description)
  SELECT 
    NEW.user_id,
    m.stat_id,
    m.level,
    CASE 
      WHEN m.level < 20 THEN 'F'
      WHEN m.level < 40 THEN 'E'
      WHEN m.level < 60 THEN 'D'
      WHEN m.level < 80 THEN 'C'
      WHEN m.level < 100 THEN 'B'
      ELSE 'A'
    END,
    m.description
  FROM milestones m
  WHERE m.id = NEW.milestone_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 트리거 생성
DROP TRIGGER IF EXISTS trigger_add_growth_record ON user_milestones;
CREATE TRIGGER trigger_add_growth_record
  AFTER INSERT ON user_milestones
  FOR EACH ROW
  EXECUTE FUNCTION add_growth_record_on_milestone();

-- 트리거 함수: 목표 달성 시 자동 완료 처리
CREATE OR REPLACE FUNCTION check_goal_completion()
RETURNS TRIGGER AS $$
BEGIN
  -- 목표 달성 확인
  UPDATE stat_goals 
  SET is_completed = TRUE, updated_at = NOW()
  WHERE user_id = NEW.user_id 
    AND stat_id = (SELECT stat_id FROM milestones WHERE id = NEW.milestone_id)
    AND is_completed = FALSE
    AND target_level <= (
      SELECT COUNT(*) 
      FROM user_milestones um2 
      JOIN milestones m2 ON um2.milestone_id = m2.id 
      WHERE um2.user_id = NEW.user_id AND m2.stat_id = (
        SELECT stat_id FROM milestones WHERE id = NEW.milestone_id
      )
    );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 트리거 생성
DROP TRIGGER IF EXISTS trigger_check_goal_completion ON user_milestones;
CREATE TRIGGER trigger_check_goal_completion
  AFTER INSERT ON user_milestones
  FOR EACH ROW
  EXECUTE FUNCTION check_goal_completion();
