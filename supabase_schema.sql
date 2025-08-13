-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Categories table
CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Skills table  
CREATE TABLE skills (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  category_id UUID REFERENCES categories(id) ON DELETE CASCADE,
  key TEXT NOT NULL UNIQUE, -- 예: "korea", "boxing", "weight_training", "running"
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Milestones table
CREATE TABLE milestones (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  skill_id UUID REFERENCES skills(id) ON DELETE CASCADE,
  level INTEGER NOT NULL,
  description TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(skill_id, level)
);

-- User milestones (completed milestones)
CREATE TABLE user_milestones (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  milestone_id UUID REFERENCES milestones(id) ON DELETE CASCADE,
  completed_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, milestone_id)
);

-- User profiles (extends auth.users)
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE,
  nickname TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert initial categories
INSERT INTO categories (name) VALUES 
  ('요리 & 식음료'),
  ('무술 & 격투기'), 
  ('피트니스 & 스포츠');

-- Insert initial skills
INSERT INTO skills (name, category_id, key) VALUES
  ('대한민국 요리', (SELECT id FROM categories WHERE name = '요리 & 식음료'), 'korea'),
  ('복싱', (SELECT id FROM categories WHERE name = '무술 & 격투기'), 'boxing'),
  ('웨이트 트레이닝', (SELECT id FROM categories WHERE name = '피트니스 & 스포츠'), 'weight_training'),
  ('달리기', (SELECT id FROM categories WHERE name = '피트니스 & 스포츠'), 'running');

-- Trigger to automatically create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, nickname)
  VALUES (new.id, new.email, '사용자');
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- RLS Policies
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_milestones ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Public profiles are viewable by everyone." ON profiles
  FOR SELECT USING (true);

CREATE POLICY "Users can insert their own profile." ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile." ON profiles
  FOR UPDATE USING (auth.uid() = id);

-- 서비스 역할을 위한 정책 (트리거 함수에서 사용)
CREATE POLICY "Service role can manage profiles." ON profiles
  FOR ALL USING (auth.role() = 'service_role');

-- User milestones policies
CREATE POLICY "Users can view own milestones." ON user_milestones
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own milestones." ON user_milestones
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own milestones." ON user_milestones
  FOR DELETE USING (auth.uid() = user_id);

-- Public read access for reference tables
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE milestones ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Categories are viewable by everyone." ON categories
  FOR SELECT USING (true);

CREATE POLICY "Skills are viewable by everyone." ON skills
  FOR SELECT USING (true);

CREATE POLICY "Milestones are viewable by everyone." ON milestones
  FOR SELECT USING (true);

-- Functions for getting user stats
CREATE OR REPLACE FUNCTION get_user_skill_progress(p_user_id UUID, p_skill_id UUID)
RETURNS TABLE (
  skill_id UUID,
  skill_name TEXT,
  category_name TEXT,
  completed_count INTEGER,
  total_count INTEGER,
  rank TEXT,
  last_completed_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    s.id as skill_id,
    s.name as skill_name,
    c.name as category_name,
    COALESCE(completed.count, 0)::INTEGER as completed_count,
    COALESCE(total.count, 0)::INTEGER as total_count,
    CASE 
      WHEN COALESCE(completed.count, 0) = 0 THEN 'F'
      WHEN COALESCE(completed.count, 0) BETWEEN 1 AND 20 THEN 'E'
      WHEN COALESCE(completed.count, 0) BETWEEN 21 AND 40 THEN 'D'
      WHEN COALESCE(completed.count, 0) BETWEEN 41 AND 60 THEN 'C'
      WHEN COALESCE(completed.count, 0) BETWEEN 61 AND 80 THEN 'B'
      WHEN COALESCE(completed.count, 0) >= 81 THEN 'A'
    END as rank,
    completed.last_completed as last_completed_at
  FROM skills s
  JOIN categories c ON s.category_id = c.id
  LEFT JOIN (
    SELECT 
      m.skill_id,
      COUNT(*) as count,
      MAX(um.completed_at) as last_completed
    FROM user_milestones um
    JOIN milestones m ON um.milestone_id = m.id
    WHERE um.user_id = p_user_id
    GROUP BY m.skill_id
  ) completed ON s.id = completed.skill_id
  LEFT JOIN (
    SELECT m.skill_id, COUNT(*) as count
    FROM milestones m
    GROUP BY m.skill_id
  ) total ON s.id = total.skill_id
  WHERE s.id = p_skill_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_user_all_skills_progress(p_user_id UUID)
RETURNS TABLE (
  skill_id UUID,
  skill_name TEXT,
  category_name TEXT,
  completed_count INTEGER,
  total_count INTEGER,
  rank TEXT,
  last_completed_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    s.id as skill_id,
    s.name as skill_name,
    c.name as category_name,
    COALESCE(completed.count, 0)::INTEGER as completed_count,
    COALESCE(total.count, 0)::INTEGER as total_count,
    CASE 
      WHEN COALESCE(completed.count, 0) = 0 THEN 'F'
      WHEN COALESCE(completed.count, 0) BETWEEN 1 AND 20 THEN 'E'
      WHEN COALESCE(completed.count, 0) BETWEEN 21 AND 40 THEN 'D'
      WHEN COALESCE(completed.count, 0) BETWEEN 41 AND 60 THEN 'C'
      WHEN COALESCE(completed.count, 0) BETWEEN 61 AND 80 THEN 'B'
      WHEN COALESCE(completed.count, 0) >= 81 THEN 'A'
    END as rank,
    completed.last_completed as last_completed_at
  FROM skills s
  JOIN categories c ON s.category_id = c.id
  LEFT JOIN (
    SELECT 
      m.skill_id,
      COUNT(*) as count,
      MAX(um.completed_at) as last_completed
    FROM user_milestones um
    JOIN milestones m ON um.milestone_id = m.id
    WHERE um.user_id = p_user_id
    GROUP BY m.skill_id
  ) completed ON s.id = completed.skill_id
  LEFT JOIN (
    SELECT m.skill_id, COUNT(*) as count
    FROM milestones m
    GROUP BY m.skill_id
  ) total ON s.id = total.skill_id
  ORDER BY s.name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
