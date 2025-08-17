-- 퀘스트 템플릿 테이블 정리 스크립트
-- 기존 테이블에서 사용되지 않는 컬럼들을 제거합니다.

-- 1. 사용되지 않는 뷰들 먼저 제거 (컬럼 의존성 때문에)
DROP VIEW IF EXISTS popular_templates;
DROP VIEW IF EXISTS template_stats;

-- 2. 사용되지 않는 트리거 제거
DROP TRIGGER IF EXISTS template_ratings_trigger ON template_ratings;

-- 3. 사용되지 않는 함수들 제거
DROP FUNCTION IF EXISTS increment_template_usage(UUID);
DROP FUNCTION IF EXISTS update_template_average_rating(UUID);
DROP FUNCTION IF EXISTS trigger_update_template_rating();

-- 4. 사용되지 않는 테이블들 제거
DROP TABLE IF EXISTS user_template_purchases CASCADE;
DROP TABLE IF EXISTS template_ratings CASCADE;

-- 5. 사용되지 않는 인덱스들 제거
DROP INDEX IF EXISTS idx_quest_templates_is_premium;
DROP INDEX IF EXISTS idx_quest_templates_usage_count;
DROP INDEX IF EXISTS idx_quest_templates_rating;
DROP INDEX IF EXISTS idx_quest_templates_price;

-- 6. 사용되지 않는 컬럼들 제거
ALTER TABLE quest_templates DROP COLUMN IF EXISTS estimated_minutes;
ALTER TABLE quest_templates DROP COLUMN IF EXISTS tags;
ALTER TABLE quest_templates DROP COLUMN IF EXISTS price;
ALTER TABLE quest_templates DROP COLUMN IF EXISTS is_premium;
ALTER TABLE quest_templates DROP COLUMN IF EXISTS author_id;
ALTER TABLE quest_templates DROP COLUMN IF EXISTS author_name;
ALTER TABLE quest_templates DROP COLUMN IF EXISTS thumbnail_url;
ALTER TABLE quest_templates DROP COLUMN IF EXISTS usage_count;
ALTER TABLE quest_templates DROP COLUMN IF EXISTS rating;
ALTER TABLE quest_templates DROP COLUMN IF EXISTS rating_count;

-- 7. 사용되지 않는 RLS 정책들 제거 (테이블이 존재하지 않을 수 있으므로 조건부로)
DO $$
BEGIN
    -- user_template_purchases 테이블이 존재하는 경우에만 정책 제거
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'user_template_purchases') THEN
        DROP POLICY IF EXISTS "user_template_purchases_select_policy" ON user_template_purchases;
        DROP POLICY IF EXISTS "user_template_purchases_insert_policy" ON user_template_purchases;
    END IF;
    
    -- template_ratings 테이블이 존재하는 경우에만 정책 제거
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'template_ratings') THEN
        DROP POLICY IF EXISTS "template_ratings_select_policy" ON template_ratings;
        DROP POLICY IF EXISTS "template_ratings_insert_policy" ON template_ratings;
        DROP POLICY IF EXISTS "template_ratings_update_policy" ON template_ratings;
    END IF;
END $$;

-- 8. 기존 샘플 데이터 업데이트 (estimated_minutes 제거)
-- 이미 estimated_minutes 컬럼이 제거되었으므로 추가 작업 불필요

-- 9. 최종 확인
-- 현재 quest_templates 테이블 구조 확인
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'quest_templates' 
ORDER BY ordinal_position;
