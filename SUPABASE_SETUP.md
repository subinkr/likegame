# Supabase 설정 가이드

## 문제 상황
현재 회원가입 시 `AuthUnknownException(message: Received an empty response with status code 404)` 오류가 발생하고 있습니다.

이는 **Supabase 설정이 완료되지 않았기 때문**입니다.

## 해결 방법

### 1. Supabase 프로젝트 생성
1. [Supabase 콘솔](https://supabase.com/dashboard)에 로그인
2. "New project" 버튼 클릭
3. 프로젝트 정보 입력:
   - Name: `likegame` (또는 원하는 이름)
   - Organization: 본인 계정
   - Password: 데이터베이스 비밀번호 설정
   - Region: `Northeast Asia (Seoul)`

### 2. 데이터베이스 스키마 설정
1. 프로젝트 생성 완료 후 "SQL Editor" 메뉴로 이동
2. `supabase_schema.sql` 파일의 내용을 복사하여 실행
3. 테이블과 트리거가 정상적으로 생성되었는지 확인

### 3. 환경변수 설정
1. Supabase 대시보드에서 "Settings" → "API" 메뉴로 이동
2. 다음 정보를 확인:
   - **Project URL**: `https://your-project-ref.supabase.co`
   - **anon/public key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

3. 프로젝트 루트에 `.env` 파일을 생성하고 다음 내용을 입력:

```env
SUPABASE_URL=https://your-actual-project-ref.supabase.co
SUPABASE_ANON_KEY=your-actual-anon-key-here
```

**주의**: `.env` 파일은 민감한 정보를 포함하므로 Git에 커밋되지 않습니다.

### 4. 이메일 인증 설정 (선택사항)
1. Supabase 대시보드에서 "Authentication" → "Settings" 메뉴로 이동
2. "User Signups" 섹션에서:
   - "Enable email confirmations" 설정 확인
   - 필요시 이메일 템플릿 커스터마이징

### 5. RLS (Row Level Security) 정책 확인
스키마 파일에 이미 포함되어 있지만, 다음 정책들이 활성화되어 있는지 확인:
- 사용자는 자신의 프로필만 수정 가능
- 사용자는 자신의 마일스톤만 조회/생성/삭제 가능
- 카테고리, 스킬, 마일스톤은 모든 사용자가 조회 가능

## 테스트
설정 완료 후:
1. 앱을 재시작
2. 회원가입 시도
3. 정상적으로 계정이 생성되고 이메일 인증 메일이 발송되는지 확인

## 문제 해결
- 여전히 404 오류가 발생한다면 URL과 API 키가 정확한지 다시 확인
- 네트워크 오류가 발생한다면 방화벽이나 프록시 설정 확인
- 데이터베이스 오류가 발생한다면 스키마가 올바르게 적용되었는지 확인
