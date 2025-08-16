-- 스탯 프리미엄 기능 관련 모든 객체 삭제

-- 트리거 삭제
DROP TRIGGER IF EXISTS trigger_check_goal_completion ON user_milestones;
DROP TRIGGER IF EXISTS trigger_add_growth_record ON user_milestones;

-- 트리거 함수 삭제
DROP FUNCTION IF EXISTS check_goal_completion();
DROP FUNCTION IF EXISTS add_growth_record_on_milestone();

-- 성과 통계 함수 삭제
DROP FUNCTION IF EXISTS get_stat_performance(UUID);

-- 성취 배지 데이터 삭제
DELETE FROM achievements;

-- 테이블 삭제 (순서: 외래키 참조를 고려하여 역순으로)
DROP TABLE IF EXISTS user_achievements;
DROP TABLE IF EXISTS achievements;
DROP TABLE IF EXISTS user_stat_streaks;
DROP TABLE IF EXISTS stat_growth_history;
DROP TABLE IF EXISTS stat_goals;
