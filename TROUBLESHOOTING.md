# LikeGame 문제 해결 가이드

## 🚨 "permission denied for table categories" 오류

### 문제 설명
이미지에서 보이는 오류는 Supabase의 RLS(Row Level Security) 정책이 설정되지 않아서 발생하는 문제입니다.

```
데이터 로드 실패: PostgrestException(message: permission denied for table categories, code: 42501, details:, hint: null)
```

### 원인
- Supabase에서 RLS가 활성화되어 있지만 적절한 정책이 설정되지 않음
- `categories` 테이블에 대한 읽기 권한이 없음

### 해결 방법

#### 방법 1: 전체 데이터베이스 재설정 (권장)
1. Supabase 대시보드 → SQL Editor로 이동
2. `complete_database_setup.sql` 파일의 내용을 복사하여 실행
3. 이 방법은 테이블, 함수, 데이터, RLS 정책을 모두 포함합니다.

#### 방법 2: RLS 정책만 추가
1. Supabase 대시보드 → SQL Editor로 이동
2. 다음 SQL을 실행하여 RLS 정책을 추가합니다:

```sql
-- Categories 테이블에 RLS 활성화 및 정책 추가
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Categories are viewable by everyone" ON categories
    FOR SELECT USING (true);

-- Skills 테이블에 RLS 활성화 및 정책 추가
ALTER TABLE skills ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Skills are viewable by everyone" ON skills
    FOR SELECT USING (true);

-- Milestones 테이블에 RLS 활성화 및 정책 추가
ALTER TABLE milestones ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Milestones are viewable by everyone" ON milestones
    FOR SELECT USING (true);
```

3. 기존 데이터는 유지하면서 RLS 정책만 추가합니다.

#### 방법 3: 수동으로 RLS 정책 설정
Supabase SQL Editor에서 다음 SQL을 실행하세요:

```sql
-- Categories 테이블에 RLS 활성화 및 정책 추가
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Categories are viewable by everyone" ON categories
    FOR SELECT USING (true);

-- Skills 테이블에 RLS 활성화 및 정책 추가
ALTER TABLE skills ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Skills are viewable by everyone" ON skills
    FOR SELECT USING (true);

-- Milestones 테이블에 RLS 활성화 및 정책 추가
ALTER TABLE milestones ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Milestones are viewable by everyone" ON milestones
    FOR SELECT USING (true);
```

### 확인 방법
1. Supabase 대시보드 → Table Editor로 이동
2. `categories` 테이블을 선택
3. "Policies" 탭에서 정책이 설정되어 있는지 확인

## 🔧 기타 일반적인 문제

### 1. 인증 오류
**증상**: 로그인/회원가입 시 404 오류

**해결 방법**:
- `.env` 파일의 Supabase URL과 anon key가 올바른지 확인
- Supabase 프로젝트가 활성화되어 있는지 확인

### 2. 데이터 로드 실패
**증상**: 스킬 목록이나 마일스톤이 로드되지 않음

**해결 방법**:
- 데이터베이스 테이블이 올바르게 생성되었는지 확인
- 함수가 올바르게 생성되었는지 확인

### 3. 네트워크 오류
**증상**: 네트워크 연결 실패

**해결 방법**:
- 인터넷 연결 상태 확인
- 방화벽이나 프록시 설정 확인
- Supabase 서비스 상태 확인

## 📞 추가 지원

문제가 지속되면 다음을 확인해주세요:

1. **Supabase 로그 확인**:
   - Supabase 대시보드 → Logs에서 오류 로그 확인

2. **Flutter 디버그 로그 확인**:
   - 앱 실행 시 콘솔에 출력되는 디버그 메시지 확인

3. **데이터베이스 상태 확인**:
   - Supabase 대시보드 → Database에서 테이블과 데이터 확인

## 🎯 예방 방법

1. **새 프로젝트 시작 시**:
   - 항상 `complete_database_setup.sql`을 먼저 실행
   - RLS 정책이 포함되어 있는지 확인

2. **기존 프로젝트 업데이트 시**:
   - 방법 2의 SQL을 실행하여 RLS 정책 추가
   - 테이블 권한 설정 확인

3. **정기적인 확인**:
   - Supabase 대시보드에서 테이블 정책 상태 확인
   - 앱 기능 테스트를 통한 권한 문제 조기 발견
