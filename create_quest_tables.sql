-- 퀘스트 테이블 확장 (기존 컬럼들에 새로운 컬럼들 추가)
ALTER TABLE quests 
ADD COLUMN IF NOT EXISTS category TEXT,
ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS sub_tasks JSONB DEFAULT '[]',
ADD COLUMN IF NOT EXISTS repeat_pattern TEXT,
ADD COLUMN IF NOT EXISTS repeat_config JSONB,
ADD COLUMN IF NOT EXISTS estimated_minutes INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS actual_minutes INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS started_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS paused_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS time_entries JSONB DEFAULT '[]',
ADD COLUMN IF NOT EXISTS template_id UUID,
ADD COLUMN IF NOT EXISTS custom_fields JSONB,
ADD COLUMN IF NOT EXISTS difficulty TEXT DEFAULT 'F' CHECK (difficulty IN ('F', 'E', 'D', 'C', 'B', 'A'));

-- 퀘스트 템플릿 테이블 생성
CREATE TABLE IF NOT EXISTS quest_templates (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    category TEXT,
    tags TEXT[] DEFAULT '{}',
    sub_task_titles TEXT[] DEFAULT '{}',
    priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'highest')),
    difficulty TEXT DEFAULT 'F' CHECK (difficulty IN ('F', 'E', 'D', 'C', 'B', 'A')),
    estimated_minutes INTEGER DEFAULT 0,
    repeat_pattern TEXT,
    repeat_config JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS 정책 설정
ALTER TABLE quest_templates ENABLE ROW LEVEL SECURITY;

-- 사용자별 템플릿 접근 정책
CREATE POLICY "Users can view their own templates" ON quest_templates
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own templates" ON quest_templates
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own templates" ON quest_templates
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own templates" ON quest_templates
    FOR DELETE USING (auth.uid() = user_id);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_quests_user_id ON quests(user_id);
CREATE INDEX IF NOT EXISTS idx_quests_category ON quests(category);
CREATE INDEX IF NOT EXISTS idx_quests_priority ON quests(priority);
CREATE INDEX IF NOT EXISTS idx_quests_difficulty ON quests(difficulty);
CREATE INDEX IF NOT EXISTS idx_quests_due_date ON quests(due_date);
CREATE INDEX IF NOT EXISTS idx_quests_is_completed ON quests(is_completed);
CREATE INDEX IF NOT EXISTS idx_quests_started_at ON quests(started_at);

CREATE INDEX IF NOT EXISTS idx_quest_templates_user_id ON quest_templates(user_id);
CREATE INDEX IF NOT EXISTS idx_quest_templates_category ON quest_templates(category);

-- 함수 생성: 태그 검색을 위한 함수
CREATE OR REPLACE FUNCTION search_quests_by_tags(tag_array TEXT[])
RETURNS TABLE (
    id UUID,
    user_id UUID,
    title TEXT,
    description TEXT,
    stat_id UUID,
    due_date TIMESTAMP WITH TIME ZONE,
    priority TEXT,
    is_completed BOOLEAN,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    category TEXT,
    tags TEXT[],
    sub_tasks JSONB,
    repeat_pattern TEXT,
    repeat_config JSONB,
    estimated_minutes INTEGER,
    actual_minutes INTEGER,
    started_at TIMESTAMP WITH TIME ZONE,
    paused_at TIMESTAMP WITH TIME ZONE,
    time_entries JSONB,
    template_id UUID,
    custom_fields JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT q.*
    FROM quests q
    WHERE q.user_id = auth.uid()
    AND q.tags && tag_array;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 함수 생성: 카테고리별 통계
CREATE OR REPLACE FUNCTION get_quest_stats_by_category()
RETURNS TABLE (
    category TEXT,
    total_count BIGINT,
    completed_count BIGINT,
    overdue_count BIGINT,
    in_progress_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(q.category, '미분류') as category,
        COUNT(*) as total_count,
        COUNT(*) FILTER (WHERE q.is_completed) as completed_count,
        COUNT(*) FILTER (WHERE q.due_date < NOW() AND NOT q.is_completed) as overdue_count,
        COUNT(*) FILTER (WHERE q.started_at IS NOT NULL AND q.paused_at IS NULL AND NOT q.is_completed) as in_progress_count
    FROM quests q
    WHERE q.user_id = auth.uid()
    GROUP BY q.category;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
