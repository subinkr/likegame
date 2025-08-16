-- 퀘스트 테이블에 난이도 컬럼 추가
ALTER TABLE quests 
ADD COLUMN IF NOT EXISTS difficulty TEXT DEFAULT 'F' CHECK (difficulty IN ('F', 'E', 'D', 'C', 'B', 'A'));

-- 난이도 인덱스 추가
CREATE INDEX IF NOT EXISTS idx_quests_difficulty ON quests(difficulty);

-- 기존 퀘스트들의 난이도를 기본값으로 설정 (이미 있으면 무시)
UPDATE quests 
SET difficulty = 'F' 
WHERE difficulty IS NULL;
