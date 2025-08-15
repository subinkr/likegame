-- 일반 사용자가 자신의 계정을 삭제할 수 있도록 설정

-- 1. auth.users 테이블에 대한 RLS 정책 확인
-- (참고: auth 스키마는 기본적으로 RLS가 비활성화되어 있음)

-- 2. profiles 테이블에 DELETE 정책 추가 (이미 있지만 확인)
DROP POLICY IF EXISTS "Users can delete their own profile." ON profiles;
CREATE POLICY "Users can delete their own profile." ON profiles
  FOR DELETE USING (auth.uid() = id);

-- 3. 모든 관련 테이블에 DELETE 정책 확인
-- user_milestones
DROP POLICY IF EXISTS "Users can delete their own milestones." ON user_milestones;
CREATE POLICY "Users can delete their own milestones." ON user_milestones
  FOR DELETE USING (auth.uid() = user_id);

-- user_stat_priorities  
DROP POLICY IF EXISTS "Users can delete their own priorities." ON user_stat_priorities;
CREATE POLICY "Users can delete their own priorities." ON user_stat_priorities
  FOR DELETE USING (auth.uid() = user_id);

-- skills
DROP POLICY IF EXISTS "Users can delete their own skills." ON skills;
CREATE POLICY "Users can delete their own skills." ON skills
  FOR DELETE USING (auth.uid() = user_id);

-- quests
DROP POLICY IF EXISTS "Users can delete their own quests." ON quests;
CREATE POLICY "Users can delete their own quests." ON quests
  FOR DELETE USING (auth.uid() = user_id);

-- 4. 현재 정책 확인
SELECT 
  schemaname, 
  tablename, 
  policyname, 
  permissive, 
  roles, 
  cmd, 
  qual 
FROM pg_policies 
WHERE tablename IN ('profiles', 'user_milestones', 'user_stat_priorities', 'skills', 'quests')
ORDER BY tablename, policyname;
