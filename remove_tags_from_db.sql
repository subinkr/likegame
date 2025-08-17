-- 태그 관련 컬럼 제거 스크립트

-- 1. quests 테이블에서 tags 컬럼 제거
ALTER TABLE quests DROP COLUMN IF EXISTS tags CASCADE;

-- 2. quest_templates 테이블에서 tags 컬럼 제거
ALTER TABLE quest_templates DROP COLUMN IF EXISTS tags CASCADE;

-- 3. 태그 관련 인덱스 제거
DROP INDEX IF EXISTS idx_quests_tags;

-- 4. 태그 관련 함수가 있다면 제거 (있다면)
-- DROP FUNCTION IF EXISTS update_template_average_rating CASCADE;
