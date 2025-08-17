-- quests 테이블 업데이트 스크립트
-- 누락된 컬럼들을 추가합니다.

-- 1. actual_minutes 컬럼 추가
ALTER TABLE quests 
ADD COLUMN IF NOT EXISTS actual_minutes INTEGER DEFAULT 0;

-- 2. started_at 컬럼 추가
ALTER TABLE quests 
ADD COLUMN IF NOT EXISTS started_at TIMESTAMP WITH TIME ZONE;

-- 3. template_id 컬럼 추가
ALTER TABLE quests 
ADD COLUMN IF NOT EXISTS template_id UUID REFERENCES quest_templates(id) ON DELETE SET NULL;



-- 4. custom_fields 컬럼 추가
ALTER TABLE quests 
ADD COLUMN IF NOT EXISTS custom_fields JSONB;

-- 5. category 컬럼 추가
ALTER TABLE quests 
ADD COLUMN IF NOT EXISTS category TEXT;

-- 6. tags 컬럼 추가
ALTER TABLE quests 
ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}';

-- 7. sub_tasks 컬럼 추가
ALTER TABLE quests 
ADD COLUMN IF NOT EXISTS sub_tasks JSONB DEFAULT '[]';

-- 8. repeat_pattern 컬럼 추가
ALTER TABLE quests 
ADD COLUMN IF NOT EXISTS repeat_pattern TEXT;

-- 9. repeat_config 컬럼 추가
ALTER TABLE quests 
ADD COLUMN IF NOT EXISTS repeat_config JSONB;

-- 10. estimated_minutes 컬럼 추가
ALTER TABLE quests 
ADD COLUMN IF NOT EXISTS estimated_minutes INTEGER DEFAULT 0;

-- 11. 기존 데이터에 대한 기본값 설정
UPDATE quests 
SET actual_minutes = 0 
WHERE actual_minutes IS NULL;

UPDATE quests 
SET estimated_minutes = 0 
WHERE estimated_minutes IS NULL;

UPDATE quests 
SET tags = '{}' 
WHERE tags IS NULL;

UPDATE quests 
SET sub_tasks = '[]' 
WHERE sub_tasks IS NULL;

-- 12. 인덱스 추가
CREATE INDEX IF NOT EXISTS idx_quests_template_id ON quests(template_id);
CREATE INDEX IF NOT EXISTS idx_quests_started_at ON quests(started_at);
CREATE INDEX IF NOT EXISTS idx_quests_category ON quests(category);
CREATE INDEX IF NOT EXISTS idx_quests_tags ON quests USING GIN(tags);


-- 13. 권한 설정
GRANT ALL ON TABLE quests TO anon, authenticated;
