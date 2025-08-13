-- 트리거 함수 생성
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, nickname)
  VALUES (new.id, new.email, 'anonymous');
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 트리거 생성
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 기존 RLS 정책 삭제
DROP POLICY IF EXISTS "Public profiles are viewable by everyone." ON profiles;
DROP POLICY IF EXISTS "Users can insert their own profile." ON profiles;
DROP POLICY IF EXISTS "Users can update own profile." ON profiles;
DROP POLICY IF EXISTS "Service role can manage profiles." ON profiles;
DROP POLICY IF EXISTS "Authenticated users can insert their own profile." ON profiles;
DROP POLICY IF EXISTS "Authenticated users can insert own profile." ON profiles;
DROP POLICY IF EXISTS "Authenticated users can update own profile." ON profiles;
DROP POLICY IF EXISTS "Service role can manage all profiles." ON profiles;

-- 새로운 RLS 정책 생성 (트리거만 사용)
-- 모든 사용자가 프로필을 조회할 수 있음
CREATE POLICY "Public profiles are viewable by everyone." ON profiles
  FOR SELECT USING (true);

-- 인증된 사용자가 자신의 프로필을 업데이트할 수 있음 (닉네임 수정용)
CREATE POLICY "Users can update own profile." ON profiles
  FOR UPDATE USING (auth.uid() = id);

-- 서비스 역할이 모든 작업을 할 수 있음 (트리거 함수용)
CREATE POLICY "Service role can manage profiles." ON profiles
  FOR ALL USING (auth.role() = 'service_role');

-- nickname 필드에 기본값 설정 (이미 있다면 무시됨)
ALTER TABLE profiles ALTER COLUMN nickname SET DEFAULT 'anonymous';
