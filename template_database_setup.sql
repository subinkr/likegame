-- 프리미엄 퀘스트 템플릿 시스템 데이터베이스 설정

-- 1. 퀘스트 템플릿 테이블
CREATE TABLE IF NOT EXISTS quest_templates (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    category TEXT NOT NULL,
    sub_tasks JSONB DEFAULT '[]',
    difficulty TEXT DEFAULT 'F' CHECK (difficulty IN ('F', 'E', 'D', 'C', 'B', 'A')),
    repeat_pattern TEXT CHECK (repeat_pattern IN ('daily', 'weekly', 'monthly', 'yearly', 'custom')),
    repeat_config JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_quest_templates_category ON quest_templates(category);
CREATE INDEX IF NOT EXISTS idx_quest_templates_difficulty ON quest_templates(difficulty);
CREATE INDEX IF NOT EXISTS idx_quest_templates_created_at ON quest_templates(created_at DESC);

-- 3. RLS (Row Level Security) 정책 설정

-- 퀘스트 템플릿 테이블 RLS
ALTER TABLE quest_templates ENABLE ROW LEVEL SECURITY;

-- 모든 사용자가 템플릿을 조회할 수 있음
CREATE POLICY "quest_templates_select_policy" ON quest_templates
    FOR SELECT USING (true);

-- 관리자만 템플릿을 생성/수정/삭제할 수 있음 (선택사항)
CREATE POLICY "quest_templates_insert_policy" ON quest_templates
    FOR INSERT WITH CHECK (auth.uid() IN (
        SELECT id FROM auth.users WHERE email IN ('admin@example.com')
    ));

CREATE POLICY "quest_templates_update_policy" ON quest_templates
    FOR UPDATE USING (auth.uid() IN (
        SELECT id FROM auth.users WHERE email IN ('admin@example.com')
    ));

CREATE POLICY "quest_templates_delete_policy" ON quest_templates
    FOR DELETE USING (auth.uid() IN (
        SELECT id FROM auth.users WHERE email IN ('admin@example.com')
    ));

-- 4. 샘플 데이터 삽입

-- 무료 템플릿들
INSERT INTO quest_templates (title, description, category, sub_tasks, difficulty) VALUES
(
    '기본 일일 루틴',
    '매일 실천할 수 있는 기본적인 자기계발 루틴',
    '자기계발',
    '[
        {"id": "1", "title": "물 마시기 (8잔)", "is_completed": false, "created_at": "2024-01-01T00:00:00Z"},
        {"id": "2", "title": "30분 운동하기", "is_completed": false, "created_at": "2024-01-01T00:00:00Z"},
        {"id": "3", "title": "독서 30분", "is_completed": false, "created_at": "2024-01-01T00:00:00Z"}
    ]'::jsonb,
    'F'
),
(
    '학습 계획 세우기',
    '효과적인 학습을 위한 계획 수립 퀘스트',
    '학습',
    '[
        {"id": "1", "title": "학습 목표 설정", "is_completed": false, "created_at": "2024-01-01T00:00:00Z"},
        {"id": "2", "title": "학습 일정 계획", "is_completed": false, "created_at": "2024-01-01T00:00:00Z"},
        {"id": "3", "title": "학습 자료 준비", "is_completed": false, "created_at": "2024-01-01T00:00:00Z"},
        {"id": "4", "title": "진도 체크 방법 설정", "is_completed": false, "created_at": "2024-01-01T00:00:00Z"}
    ]'::jsonb,
    'E'
),
(
    '건강한 식습관 만들기',
    '건강한 식습관을 형성하기 위한 단계별 퀘스트',
    '건강',
    '[
        {"id": "1", "title": "현재 식습관 분석", "is_completed": false, "created_at": "2024-01-01T00:00:00Z"},
        {"id": "2", "title": "건강한 식단 계획", "is_completed": false, "created_at": "2024-01-01T00:00:00Z"},
        {"id": "3", "title": "식재료 구매 계획", "is_completed": false, "created_at": "2024-01-01T00:00:00Z"},
        {"id": "4", "title": "요리 실습", "is_completed": false, "created_at": "2024-01-01T00:00:00Z"},
        {"id": "5", "title": "식습관 개선 평가", "is_completed": false, "created_at": "2024-01-01T00:00:00Z"}
    ]'::jsonb,
    'D'
),
(
    '프로그래밍 마스터 로드맵',
    '초보자부터 전문가까지 프로그래밍 실력을 단계별로 향상시키는 종합 로드맵',
    '프로그래밍',
    '[
        {"id": "1", "title": "프로그래밍 언어 선택 및 설치", "is_completed": false, "created_at": "2024-01-01T00:00:00Z"},
        {"id": "2", "title": "기본 문법 학습 (2주)", "is_completed": false, "created_at": "2024-01-01T00:00:00Z"},
        {"id": "3", "title": "간단한 프로그램 작성", "is_completed": false, "created_at": "2024-01-01T00:00:00Z"},
        {"id": "4", "title": "알고리즘 기초 학습", "is_completed": false, "created_at": "2024-01-01T00:00:00Z"},
        {"id": "5", "title": "데이터 구조 학습", "is_completed": false, "created_at": "2024-01-01T00:00:00Z"},
        {"id": "6", "title": "프로젝트 기획 및 설계", "is_completed": false, "created_at": "2024-01-01T00:00:00Z"},
        {"id": "7", "title": "실제 프로젝트 개발", "is_completed": false, "created_at": "2024-01-01T00:00:00Z"},
        {"id": "8", "title": "코드 리뷰 및 개선", "is_completed": false, "created_at": "2024-01-01T00:00:00Z"},
        {"id": "9", "title": "버전 관리 시스템 학습", "is_completed": false, "created_at": "2024-01-01T00:00:00Z"},
        {"id": "10", "title": "포트폴리오 작성", "is_completed": false, "created_at": "2024-01-01T00:00:00Z"}
    ]'::jsonb,
    'A'
),
(
    '체력 단련 30일 챌린지',
    '30일 동안 체계적으로 체력을 향상시키는 고강도 훈련 프로그램',
    '피트니스',
    '[
        {"id": "1", "title": "현재 체력 상태 측정", "is_completed": false, "created_at": "2024-01-01T00:00:00Z"},
        {"id": "2", "title": "1주차: 기초 체력 단련", "is_completed": false, "created_at": "2024-01-01T00:00:00Z"},
        {"id": "3", "title": "2주차: 근력 강화", "is_completed": false, "created_at": "2024-01-01T00:00:00Z"},
        {"id": "4", "title": "3주차: 지구력 향상", "is_completed": false, "created_at": "2024-01-01T00:00:00Z"},
        {"id": "5", "title": "4주차: 고강도 훈련", "is_completed": false, "created_at": "2024-01-01T00:00:00Z"},
        {"id": "6", "title": "최종 체력 측정 및 평가", "is_completed": false, "created_at": "2024-01-01T00:00:00Z"}
    ]'::jsonb,
    'B'
),
(
    '언어 학습 90일 마스터',
    '90일 동안 새로운 언어를 마스터하는 체계적인 학습 프로그램',
    '언어학습',
    '[
        {"id": "1", "title": "학습할 언어 선택 및 목표 설정", "is_completed": false, "created_at": "2024-01-01T00:00:00Z"},
        {"id": "2", "title": "1-30일: 기초 문법 및 어휘", "is_completed": false, "created_at": "2024-01-01T00:00:00Z"},
        {"id": "3", "title": "31-60일: 회화 및 듣기 연습", "is_completed": false, "created_at": "2024-01-01T00:00:00Z"},
        {"id": "4", "title": "61-90일: 고급 표현 및 문화 학습", "is_completed": false, "created_at": "2024-01-01T00:00:00Z"},
        {"id": "5", "title": "실전 대화 연습", "is_completed": false, "created_at": "2024-01-01T00:00:00Z"},
        {"id": "6", "title": "언어 능력 평가 및 인증", "is_completed": false, "created_at": "2024-01-01T00:00:00Z"}
    ]'::jsonb,
    'A'
),
(
    '창업 준비 완벽 가이드',
    '창업을 위한 모든 준비 과정을 단계별로 안내하는 종합 가이드',
    '창업',
    '[
        {"id": "1", "title": "창업 아이디어 구체화", "is_completed": false, "created_at": "2024-01-01T00:00:00Z"},
        {"id": "2", "title": "시장 조사 및 분석", "is_completed": false, "created_at": "2024-01-01T00:00:00Z"},
        {"id": "3", "title": "비즈니스 모델 설계", "is_completed": false, "created_at": "2024-01-01T00:00:00Z"},
        {"id": "4", "title": "사업계획서 작성", "is_completed": false, "created_at": "2024-01-01T00:00:00Z"},
        {"id": "5", "title": "자금 조달 계획", "is_completed": false, "created_at": "2024-01-01T00:00:00Z"},
        {"id": "6", "title": "법적 절차 및 등록", "is_completed": false, "created_at": "2024-01-01T00:00:00Z"},
        {"id": "7", "title": "팀 구성 및 조직 설계", "is_completed": false, "created_at": "2024-01-01T00:00:00Z"},
        {"id": "8", "title": "마케팅 전략 수립", "is_completed": false, "created_at": "2024-01-01T00:00:00Z"},
        {"id": "9", "title": "운영 시스템 구축", "is_completed": false, "created_at": "2024-01-01T00:00:00Z"},
        {"id": "10", "title": "창업 실행 및 런칭", "is_completed": false, "created_at": "2024-01-01T00:00:00Z"}
    ]'::jsonb,
    'A'
);

-- 5. 권한 설정
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated;

