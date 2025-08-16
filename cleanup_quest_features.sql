-- 퀘스트 관련 불필요한 프리미엄 기능 정리

-- 1. 퀘스트 템플릿 테이블 삭제
DROP TABLE IF EXISTS quest_templates CASCADE;

-- 2. 퀘스트 테이블에서 불필요한 컬럼들 제거
ALTER TABLE quests 
DROP COLUMN IF EXISTS category,
DROP COLUMN IF EXISTS tags,
DROP COLUMN IF EXISTS sub_tasks,
DROP COLUMN IF EXISTS repeat_pattern,
DROP COLUMN IF EXISTS repeat_config,
DROP COLUMN IF EXISTS estimated_minutes,
DROP COLUMN IF EXISTS actual_minutes,
DROP COLUMN IF EXISTS started_at,
DROP COLUMN IF EXISTS paused_at,
DROP COLUMN IF EXISTS time_entries,
DROP COLUMN IF EXISTS template_id,
DROP COLUMN IF EXISTS custom_fields;

-- 3. 관련 인덱스 삭제
DROP INDEX IF EXISTS idx_quests_category;
DROP INDEX IF EXISTS idx_quests_started_at;

-- 4. 관련 함수들 삭제
DROP FUNCTION IF EXISTS search_quests_by_tags(TEXT[]);
DROP FUNCTION IF EXISTS get_quest_stats_by_category();

-- 5. stat_id 컬럼 제거 (실제로 사용되지 않음)
ALTER TABLE quests DROP COLUMN IF EXISTS stat_id;

-- 6. 기존 인덱스 재생성 (필요한 것들만)
DROP INDEX IF EXISTS idx_quests_user_id;
DROP INDEX IF EXISTS idx_quests_due_date;
DROP INDEX IF EXISTS idx_quests_is_completed;
DROP INDEX IF EXISTS idx_quests_priority;
DROP INDEX IF EXISTS idx_quests_difficulty;

CREATE INDEX IF NOT EXISTS idx_quests_user_id ON quests(user_id);
CREATE INDEX IF NOT EXISTS idx_quests_due_date ON quests(due_date);
CREATE INDEX IF NOT EXISTS idx_quests_is_completed ON quests(is_completed);
CREATE INDEX IF NOT EXISTS idx_quests_priority ON quests(priority);
CREATE INDEX IF NOT EXISTS idx_quests_difficulty ON quests(difficulty);
