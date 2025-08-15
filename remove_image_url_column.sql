-- 스킬 테이블에서 image_url 컬럼 제거
ALTER TABLE skills DROP COLUMN IF EXISTS image_url;

-- 스킬 이미지 스토리지 버킷도 삭제 (선택사항)
-- DROP POLICY IF EXISTS "Users can upload skill images" ON storage.objects;
-- DROP POLICY IF EXISTS "Users can view own skill images" ON storage.objects;
-- DROP POLICY IF EXISTS "Users can delete own skill images" ON storage.objects;

-- 스토리지 버킷 삭제 (주의: 모든 이미지가 삭제됩니다)
-- DROP BUCKET IF EXISTS skill-images;

-- 변경사항 확인
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'skills' 
ORDER BY ordinal_position;
