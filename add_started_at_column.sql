-- 퀘스트 테이블에 started_at 컬럼 추가
ALTER TABLE quests 
ADD COLUMN IF NOT EXISTS started_at TIMESTAMP WITH TIME ZONE;

-- 인덱스 생성 (선택사항)
CREATE INDEX IF NOT EXISTS idx_quests_started_at ON quests(started_at);

-- 기존 퀘스트들의 started_at을 NULL로 설정
UPDATE quests SET started_at = NULL WHERE started_at IS NULL;
