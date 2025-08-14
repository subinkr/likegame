-- =====================================================
-- LikeGame 완전한 데이터베이스 스키마
-- =====================================================

-- 1. 테이블 생성

-- 사용자 프로필 테이블
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  nickname TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 스탯 테이블 (기존 skills에서 변경)
CREATE TABLE IF NOT EXISTS stats (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  key TEXT UNIQUE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 마일스톤 테이블
CREATE TABLE IF NOT EXISTS milestones (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  stat_id UUID REFERENCES stats(id) ON DELETE CASCADE NOT NULL,
  level INTEGER NOT NULL,
  description TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 사용자 마일스톤 완료 테이블
CREATE TABLE IF NOT EXISTS user_milestones (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  milestone_id UUID REFERENCES milestones(id) ON DELETE CASCADE,
  completed_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, milestone_id)
);

-- 2. 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_milestones_stat_id ON milestones(stat_id);
CREATE INDEX IF NOT EXISTS idx_milestones_level ON milestones(level);
CREATE INDEX IF NOT EXISTS idx_user_milestones_user_id ON user_milestones(user_id);
CREATE INDEX IF NOT EXISTS idx_user_milestones_milestone_id ON user_milestones(milestone_id);

-- 3. RLS (Row Level Security) 정책 설정

-- profiles 테이블 RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own profile." ON profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile." ON profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile." ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- stats 테이블 RLS
ALTER TABLE stats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Stats are viewable by everyone." ON stats
  FOR SELECT USING (true);

-- milestones 테이블 RLS
ALTER TABLE milestones ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Milestones are viewable by everyone." ON milestones
  FOR SELECT USING (true);

-- user_milestones 테이블 RLS
ALTER TABLE user_milestones ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own milestones." ON user_milestones
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own milestones." ON user_milestones
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own milestones." ON user_milestones
  FOR DELETE USING (auth.uid() = user_id);

-- 4. 트리거 함수들

-- 새 사용자 등록 시 프로필 자동 생성
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, nickname)
  VALUES (NEW.id, 'anonymous');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 트리거 생성 (중복 방지)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'on_auth_user_created'
  ) THEN
    CREATE TRIGGER on_auth_user_created
      AFTER INSERT ON auth.users
      FOR EACH ROW EXECUTE FUNCTION handle_new_user();
  END IF;
END $$;

-- 5. 스탯 관련 함수들

-- 특정 스탯의 진행상황 가져오기
CREATE OR REPLACE FUNCTION get_user_stat_progress(p_user_id UUID, p_stat_id UUID)
RETURNS TABLE (
  stat_id UUID,
  stat_name TEXT,
  completed_count INTEGER,
  total_count INTEGER,
  rank TEXT,
  last_completed_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    s.id as stat_id,
    s.name as stat_name,
    COALESCE(completed.count, 0)::INTEGER as completed_count,
    COALESCE(total.count, 0)::INTEGER as total_count,
    CASE
      WHEN COALESCE(completed.count, 0) < 20 THEN 'F'
      WHEN COALESCE(completed.count, 0) BETWEEN 20 AND 39 THEN 'E'
      WHEN COALESCE(completed.count, 0) BETWEEN 40 AND 59 THEN 'D'
      WHEN COALESCE(completed.count, 0) BETWEEN 60 AND 79 THEN 'C'
      WHEN COALESCE(completed.count, 0) BETWEEN 80 AND 99 THEN 'B'
      WHEN COALESCE(completed.count, 0) >= 100 THEN 'A'
    END as rank,
    completed.last_completed as last_completed_at
  FROM stats s
  LEFT JOIN (
    SELECT
      m.stat_id,
      COUNT(*) as count,
      MAX(um.completed_at) as last_completed
    FROM user_milestones um
    JOIN milestones m ON um.milestone_id = m.id
    WHERE um.user_id = p_user_id
    GROUP BY m.stat_id
  ) completed ON s.id = completed.stat_id
  LEFT JOIN (
    SELECT m.stat_id, COUNT(*) as count
    FROM milestones m
    GROUP BY m.stat_id
  ) total ON s.id = total.stat_id
  WHERE s.id = p_stat_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 사용자의 모든 스탯 진행상황 가져오기
CREATE OR REPLACE FUNCTION get_user_all_stats_progress(p_user_id UUID)
RETURNS TABLE (
  stat_id UUID,
  stat_name TEXT,
  completed_count INTEGER,
  total_count INTEGER,
  rank TEXT,
  last_completed_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    s.id as stat_id,
    s.name as stat_name,
    COALESCE(completed.count, 0)::INTEGER as completed_count,
    COALESCE(total.count, 0)::INTEGER as total_count,
    CASE
      WHEN COALESCE(completed.count, 0) < 20 THEN 'F'
      WHEN COALESCE(completed.count, 0) BETWEEN 20 AND 39 THEN 'E'
      WHEN COALESCE(completed.count, 0) BETWEEN 40 AND 59 THEN 'D'
      WHEN COALESCE(completed.count, 0) BETWEEN 60 AND 79 THEN 'C'
      WHEN COALESCE(completed.count, 0) BETWEEN 80 AND 99 THEN 'B'
      WHEN COALESCE(completed.count, 0) >= 100 THEN 'A'
    END as rank,
    completed.last_completed as last_completed_at
  FROM stats s
  LEFT JOIN (
    SELECT
      m.stat_id,
      COUNT(*) as count,
      MAX(um.completed_at) as last_completed
    FROM user_milestones um
    JOIN milestones m ON um.milestone_id = m.id
    WHERE um.user_id = p_user_id
    GROUP BY m.stat_id
  ) completed ON s.id = completed.stat_id
  LEFT JOIN (
    SELECT m.stat_id, COUNT(*) as count
    FROM milestones m
    GROUP BY m.stat_id
  ) total ON s.id = total.stat_id
  ORDER BY s.name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 특정 스탯의 완료된 마일스톤 ID 목록 가져오기
CREATE OR REPLACE FUNCTION get_completed_milestone_ids(p_user_id UUID, p_stat_id UUID)
RETURNS TABLE (milestone_id UUID) AS $$
BEGIN
  RETURN QUERY
  SELECT um.milestone_id
  FROM user_milestones um
  JOIN milestones m ON um.milestone_id = m.id
  WHERE um.user_id = p_user_id AND m.stat_id = p_stat_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 마일스톤 완료 처리
CREATE OR REPLACE FUNCTION complete_milestone(p_user_id UUID, p_milestone_id UUID)
RETURNS VOID AS $$
BEGIN
  INSERT INTO user_milestones (user_id, milestone_id)
  VALUES (p_user_id, p_milestone_id)
  ON CONFLICT (user_id, milestone_id) DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 마일스톤 완료 취소 처리
CREATE OR REPLACE FUNCTION uncomplete_milestone(p_user_id UUID, p_milestone_id UUID)
RETURNS VOID AS $$
BEGIN
  DELETE FROM user_milestones
  WHERE user_id = p_user_id AND milestone_id = p_milestone_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 스탯 통계 정보 가져오기
CREATE OR REPLACE FUNCTION get_stat_summary(p_user_id UUID)
RETURNS TABLE (
  total_stats INTEGER,
  completed_stats INTEGER,
  total_milestones INTEGER,
  completed_milestones INTEGER,
  average_rank TEXT
) AS $$
DECLARE
  v_total_stats INTEGER;
  v_completed_stats INTEGER;
  v_total_milestones INTEGER;
  v_completed_milestones INTEGER;
  v_avg_completed_count NUMERIC;
BEGIN
  -- 전체 스탯 수
  SELECT COUNT(*) INTO v_total_stats FROM stats;

  -- 완료된 스탯 수 (마일스톤이 1개 이상 완료된 스탯)
  SELECT COUNT(*) INTO v_completed_stats
  FROM (
    SELECT s.id
    FROM stats s
    LEFT JOIN (
      SELECT m.stat_id, COUNT(*) as count
      FROM user_milestones um
      JOIN milestones m ON um.milestone_id = m.id
      WHERE um.user_id = p_user_id
      GROUP BY m.stat_id
    ) completed ON s.id = completed.stat_id
    WHERE COALESCE(completed.count, 0) > 0
  ) completed_stats;

  -- 전체 마일스톤 수
  SELECT COUNT(*) INTO v_total_milestones FROM milestones;

  -- 완료된 마일스톤 수
  SELECT COUNT(*) INTO v_completed_milestones
  FROM user_milestones
  WHERE user_id = p_user_id;

  -- 평균 완료 마일스톤 수
  SELECT AVG(completed.count) INTO v_avg_completed_count
  FROM (
    SELECT m.stat_id, COUNT(*) as count
    FROM user_milestones um
    JOIN milestones m ON um.milestone_id = m.id
    WHERE um.user_id = p_user_id
    GROUP BY m.stat_id
  ) completed;

  RETURN QUERY
  SELECT
    v_total_stats::INTEGER,
    v_completed_stats::INTEGER,
    v_total_milestones::INTEGER,
    v_completed_milestones::INTEGER,
    CASE
      WHEN v_avg_completed_count IS NULL OR v_avg_completed_count < 20 THEN 'F'
      WHEN v_avg_completed_count BETWEEN 20 AND 39 THEN 'E'
      WHEN v_avg_completed_count BETWEEN 40 AND 59 THEN 'D'
      WHEN v_avg_completed_count BETWEEN 60 AND 79 THEN 'C'
      WHEN v_avg_completed_count BETWEEN 80 AND 99 THEN 'B'
      WHEN v_avg_completed_count >= 100 THEN 'A'
    END as average_rank;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. 기본 데이터 삽입 (32개 스탯)

-- 32개 스탯 데이터 삽입
INSERT INTO stats (name, key) VALUES
('근력', 'strength'),
('민첩', 'agility'),
('지혜', 'wisdom'),
('지능', 'intelligence'),
('매력', 'charisma'),
('체력', 'constitution'),
('인내', 'patience'),
('집중', 'focus'),
('창의성', 'creativity'),
('리더십', 'leadership'),
('의사소통', 'communication'),
('문제해결', 'problem_solving'),
('팀워크', 'teamwork'),
('적응력', 'adaptability'),
('학습능력', 'learning_ability'),
('기억력', 'memory'),
('분석력', 'analytical_thinking'),
('판단력', 'judgment'),
('계획력', 'planning'),
('조직력', 'organization'),
('시간관리', 'time_management'),
('스트레스관리', 'stress_management'),
('감정조절', 'emotion_control'),
('동기부여', 'motivation'),
('목표설정', 'goal_setting'),
('자기관리', 'self_management'),
('의사결정', 'decision_making'),
('협상능력', 'negotiation'),
('프레젠테이션', 'presentation'),
('네트워킹', 'networking'),
('혁신', 'innovation'),
('통찰력', 'insight')
ON CONFLICT (key) DO NOTHING;

-- 7. 확인용 쿼리
SELECT 'Schema setup completed successfully' as status;
SELECT COUNT(*) as stats_count FROM stats;
SELECT COUNT(*) as milestones_count FROM milestones;
SELECT routine_name FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name LIKE '%stat%' OR routine_name LIKE '%milestone%'
ORDER BY routine_name;
