-- 기존 성취 배지 데이터 삭제
DELETE FROM achievements;

-- 수정된 성취 배지 데이터 삽입
INSERT INTO achievements (id, name, description, icon, category, required_value, condition) VALUES
('first_milestone', '첫 걸음', '첫 번째 마일스톤을 달성했습니다', '🎯', 'milestone', 1, 'first_milestone'),
('milestone_count_10', '열정의 시작', '10개의 마일스톤을 달성했습니다', '🔥', 'milestone', 10, 'milestone_count'),
('milestone_count_50', '성장하는 자', '50개의 마일스톤을 달성했습니다', '🌱', 'milestone', 50, 'milestone_count'),
('milestone_count_100', '마스터', '100개의 마일스톤을 달성했습니다', '👑', 'milestone', 100, 'milestone_count'),
('daily_streak', '연속 달성', '7일 연속으로 마일스톤을 달성했습니다', '🔥', 'streak', 7, 'daily_streak'),
('streak_30', '불굴의 의지', '30일 연속으로 마일스톤을 달성했습니다', '💪', 'streak', 30, 'daily_streak'),
('rank_up', '랭크 업', '첫 번째 랭크 업을 달성했습니다', '⭐', 'rank', 1, 'rank_up'),
('all_ranks', '성장의 여정', '모든 랭크를 경험했습니다', '🌈', 'rank', 6, 'all_ranks'),
('goal_completed', '목표 달성', '첫 번째 목표를 달성했습니다', '🎯', 'goal', 1, 'goal_completed'),
('goal_master', '계획적인 성장', '10개의 목표를 달성했습니다', '📈', 'goal', 10, 'goal_completed');
