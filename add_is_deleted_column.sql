-- profiles 테이블에 is_deleted 컬럼 추가

-- 1. is_deleted 컬럼 추가 (기본값 false)
ALTER TABLE profiles 
ADD COLUMN is_deleted BOOLEAN DEFAULT FALSE;

-- 2. 기존 데이터는 모두 false로 설정
UPDATE profiles 
SET is_deleted = FALSE 
WHERE is_deleted IS NULL;

-- 3. is_deleted 컬럼을 NOT NULL로 설정
ALTER TABLE profiles 
ALTER COLUMN is_deleted SET NOT NULL;

-- 4. 인덱스 추가 (성능 향상)
CREATE INDEX idx_profiles_is_deleted ON profiles(is_deleted);

-- 5. RLS 정책 업데이트 (삭제된 계정은 접근 불가)
DROP POLICY IF EXISTS "Users can view their own profile." ON profiles;
CREATE POLICY "Users can view their own profile." ON profiles
  FOR SELECT USING (
    auth.uid() = id AND is_deleted = FALSE
  );

-- 6. 현재 정책 확인
SELECT 
  schemaname, 
  tablename, 
  policyname, 
  permissive, 
  roles, 
  cmd, 
  qual 
FROM pg_policies 
WHERE tablename = 'profiles' 
ORDER BY policyname;
