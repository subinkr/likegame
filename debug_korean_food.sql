-- 1. 스킬 확인
SELECT id, name, key FROM skills WHERE name = '대한민국 요리';

-- 2. 마일스톤 확인
SELECT 
  m.id,
  m.level,
  m.description,
  s.name as skill_name,
  s.key as skill_key
FROM milestones m
JOIN skills s ON m.skill_id = s.id
WHERE s.name = '대한민국 요리'
ORDER BY m.level
LIMIT 10;

-- 3. 마일스톤 개수 확인
SELECT 
  s.name as skill_name,
  s.key as skill_key,
  COUNT(m.id) as milestone_count
FROM skills s
LEFT JOIN milestones m ON s.id = m.skill_id
GROUP BY s.id, s.name, s.key
ORDER BY s.name;

-- 4. 스킬 ID로 직접 마일스톤 확인
SELECT 
  m.id,
  m.level,
  m.description
FROM milestones m
WHERE m.skill_id = (SELECT id FROM skills WHERE key = 'korean_food')
ORDER BY m.level
LIMIT 5;

-- 5. 모든 스킬과 마일스톤 개수 확인
SELECT 
  s.name as skill_name,
  s.key as skill_key,
  s.id as skill_id,
  COUNT(m.id) as milestone_count
FROM skills s
LEFT JOIN milestones m ON s.id = m.skill_id
GROUP BY s.id, s.name, s.key
ORDER BY s.name;

-- 6. 데이터베이스 함수 테스트 (사용자 ID 필요)
-- SELECT * FROM get_user_all_skills_progress('사용자UUID');

-- 7. 스킬 키별 마일스톤 개수 상세 확인
SELECT 
  s.key as skill_key,
  s.name as skill_name,
  COUNT(m.id) as total_milestones,
  CASE 
    WHEN COUNT(m.id) = 0 THEN '마일스톤 없음'
    WHEN COUNT(m.id) < 10 THEN '마일스톤 부족'
    ELSE '정상'
  END as status
FROM skills s
LEFT JOIN milestones m ON s.id = m.skill_id
GROUP BY s.id, s.key, s.name
ORDER BY s.name;

-- 8. 마일스톤이 없는 스킬 확인
SELECT 
  s.id,
  s.name,
  s.key
FROM skills s
LEFT JOIN milestones m ON s.id = m.skill_id
WHERE m.id IS NULL;
