-- 퀘스트 테이블 생성
CREATE TABLE IF NOT EXISTS quests (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  stat_id UUID REFERENCES stats(id) ON DELETE SET NULL,
  due_date TIMESTAMP WITH TIME ZONE,
  priority TEXT CHECK (priority IN ('low', 'normal', 'high', 'highest')) DEFAULT 'normal',
  is_completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_quests_user_id ON quests(user_id);
CREATE INDEX IF NOT EXISTS idx_quests_stat_id ON quests(stat_id);
CREATE INDEX IF NOT EXISTS idx_quests_due_date ON quests(due_date);
CREATE INDEX IF NOT EXISTS idx_quests_is_completed ON quests(is_completed);
CREATE INDEX IF NOT EXISTS idx_quests_priority ON quests(priority);

-- RLS 활성화
ALTER TABLE quests ENABLE ROW LEVEL SECURITY;

-- RLS 정책 생성
CREATE POLICY "Users can view own quests" ON quests
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own quests" ON quests
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own quests" ON quests
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own quests" ON quests
  FOR DELETE USING (auth.uid() = user_id);

-- updated_at 자동 업데이트 함수
CREATE OR REPLACE FUNCTION update_quests_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- completed_at 자동 설정 함수
CREATE OR REPLACE FUNCTION set_quest_completed_at()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.is_completed = TRUE AND OLD.is_completed = FALSE THEN
    NEW.completed_at = NOW();
  ELSIF NEW.is_completed = FALSE THEN
    NEW.completed_at = NULL;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 트리거 생성
CREATE TRIGGER trigger_update_quests_updated_at
  BEFORE UPDATE ON quests
  FOR EACH ROW
  EXECUTE FUNCTION update_quests_updated_at();

CREATE TRIGGER trigger_set_quests_completed_at
  BEFORE UPDATE ON quests
  FOR EACH ROW
  EXECUTE FUNCTION set_quest_completed_at();

-- 퀘스트 통계 함수
CREATE OR REPLACE FUNCTION get_quest_statistics(p_user_id UUID)
RETURNS TABLE(
  total_quests BIGINT,
  completed_quests BIGINT,
  pending_quests BIGINT,
  overdue_quests BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*) as total_quests,
    COUNT(*) FILTER (WHERE is_completed = TRUE) as completed_quests,
    COUNT(*) FILTER (WHERE is_completed = FALSE) as pending_quests,
    COUNT(*) FILTER (WHERE is_completed = FALSE AND due_date < NOW()) as overdue_quests
  FROM quests
  WHERE user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 특정 스탯의 퀘스트 가져오기 함수
CREATE OR REPLACE FUNCTION get_quests_by_stat(p_user_id UUID, p_stat_id UUID)
RETURNS TABLE(
  id UUID,
  title TEXT,
  description TEXT,
  stat_id UUID,
  due_date TIMESTAMP WITH TIME ZONE,
  priority TEXT,
  is_completed BOOLEAN,
  completed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    q.id,
    q.title,
    q.description,
    q.stat_id,
    q.due_date,
    q.priority,
    q.is_completed,
    q.completed_at,
    q.created_at,
    q.updated_at
  FROM quests q
  WHERE q.user_id = p_user_id AND q.stat_id = p_stat_id
  ORDER BY q.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 오늘 마감인 퀘스트 가져오기 함수
CREATE OR REPLACE FUNCTION get_today_quests(p_user_id UUID)
RETURNS TABLE(
  id UUID,
  title TEXT,
  description TEXT,
  stat_id UUID,
  due_date TIMESTAMP WITH TIME ZONE,
  priority TEXT,
  is_completed BOOLEAN,
  completed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    q.id,
    q.title,
    q.description,
    q.stat_id,
    q.due_date,
    q.priority,
    q.is_completed,
    q.completed_at,
    q.created_at,
    q.updated_at
  FROM quests q
  WHERE q.user_id = p_user_id 
    AND q.due_date::date = CURRENT_DATE
    AND q.is_completed = FALSE
  ORDER BY q.priority DESC, q.created_at ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
