-- 사용자별 스탯 우선순위 테이블 생성
CREATE TABLE IF NOT EXISTS user_stat_priorities (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  stat_id UUID NOT NULL REFERENCES stats(id) ON DELETE CASCADE,
  priority_order INTEGER NOT NULL DEFAULT 999,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- 사용자당 스탯당 하나의 우선순위만 설정 가능
  UNIQUE(user_id, stat_id)
);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_user_stat_priorities_user_id ON user_stat_priorities(user_id);
CREATE INDEX IF NOT EXISTS idx_user_stat_priorities_priority_order ON user_stat_priorities(priority_order);

-- RLS 정책 설정
ALTER TABLE user_stat_priorities ENABLE ROW LEVEL SECURITY;

-- 사용자는 자신의 스탯 우선순위만 볼 수 있음
CREATE POLICY "Users can view own stat priorities" ON user_stat_priorities
  FOR SELECT USING (auth.uid() = user_id);

-- 사용자는 자신의 스탯 우선순위만 수정할 수 있음
CREATE POLICY "Users can insert own stat priorities" ON user_stat_priorities
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 사용자는 자신의 스탯 우선순위만 수정할 수 있음
CREATE POLICY "Users can update own stat priorities" ON user_stat_priorities
  FOR UPDATE USING (auth.uid() = user_id);

-- 사용자는 자신의 스탯 우선순위만 삭제할 수 있음
CREATE POLICY "Users can delete own stat priorities" ON user_stat_priorities
  FOR DELETE USING (auth.uid() = user_id);

-- 기존 함수 삭제 (타입 변경을 위해)
DROP FUNCTION IF EXISTS get_user_stats_with_priorities(UUID);

-- 사용자의 우선순위가 설정된 스탯들을 가져오는 함수
CREATE OR REPLACE FUNCTION get_user_stats_with_priorities(p_user_id UUID)
RETURNS TABLE(
  stat_id UUID,
  stat_name TEXT,
  stat_description TEXT,
  priority_order INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    s.id as stat_id,
    s.name as stat_name,
    s.description as stat_description,
    COALESCE(usp.priority_order, 999) as priority_order
  FROM stats s
  LEFT JOIN user_stat_priorities usp ON s.id = usp.stat_id AND usp.user_id = p_user_id
  ORDER BY COALESCE(usp.priority_order, 999), s.name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
