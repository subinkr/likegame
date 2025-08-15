-- profiles 테이블에 DELETE 정책 추가
-- 사용자가 자신의 프로필을 삭제할 수 있도록 허용

-- 기존 DELETE 정책이 있다면 삭제
DROP POLICY IF EXISTS "Users can delete their own profile." ON profiles;

-- 새로운 DELETE 정책 생성
CREATE POLICY "Users can delete their own profile." ON profiles
  FOR DELETE USING (auth.uid() = id);

-- 정책이 제대로 생성되었는지 확인
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'profiles' 
ORDER BY policyname;
