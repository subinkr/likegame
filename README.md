# LikeGame - 스킬 수치화 자기계발 앱

스킬을 수치화하고 마일스톤을 달성하여 랭크를 올리는 자기계발 앱입니다.

## 🚀 주요 기능

- **스킬 수치화**: 다양한 카테고리의 스킬을 100개의 마일스톤으로 세분화
- **랭크 시스템**: F ~ A 등급까지 5단계 랭크 시스템
- **마일스톤 관리**: 20개 단위로 묶인 마일스톤을 완료하여 랭크 상승
- **진행률 추적**: 실시간 진행률 확인 및 통계
- **이메일 인증**: Supabase 기반 안전한 회원가입/로그인

## 📱 화면 구성

1. **로그인/회원가입 화면**: 이메일 인증 기반 사용자 관리
2. **스탯 화면**: 닉네임, 상위 스킬 3개, 최근 성장 스킬 3개 표시
3. **스킬 목록 화면**: 검색 및 카테고리 필터링 기능이 있는 스킬 그리드
4. **스킬 랭크 화면**: E~A 등급별 진행상황 표시
5. **마일스톤 화면**: 각 랭크별 마일스톤 목록 및 완료 처리

## 🛠 기술 스택

- **Frontend**: Flutter
- **Backend**: Supabase (PostgreSQL, Auth, Realtime)
- **State Management**: StatefulWidget (추후 Provider/Riverpod 도입 고려)

## 📂 프로젝트 구조

```
lib/
├── config/                 # 설정 파일
│   └── supabase_config.dart
├── models/                 # 데이터 모델
│   └── models.dart
├── services/               # 비즈니스 로직
│   ├── auth_service.dart
│   └── skill_service.dart
├── screens/                # UI 화면
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── main_screen.dart
│   ├── stats_screen.dart
│   ├── skills_screen.dart
│   ├── skill_ranks_screen.dart
│   └── milestones_screen.dart
└── main.dart
```

## ⚙️ 설정 방법

### 1. Supabase 프로젝트 생성

1. [Supabase](https://supabase.com)에서 새 프로젝트 생성
2. 프로젝트 URL과 anon key를 복사

### 2. 설정 파일 수정

`lib/config/supabase_config.dart` 파일을 수정하세요:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
}
```

### 3. 데이터베이스 설정

Supabase SQL Editor에서 다음 파일들을 순서대로 실행하세요:

1. `complete_database_setup.sql` - 전체 데이터베이스 설정 (테이블, 함수, 데이터, RLS 정책 포함)

### 4. Flutter 프로젝트 실행

```bash
# 의존성 설치
flutter pub get

# 앱 실행
flutter run
```

## 🎯 포함된 스킬 데이터

### 요리 & 식음료
- **대한민국 요리** (100개 마일스톤)

### 무술 & 격투기  
- **복싱** (100개 마일스톤)

### 피트니스 & 스포츠
- **웨이트 트레이닝** (100개 마일스톤)
- **달리기** (100개 마일스톤)

## 🏆 랭크 시스템

- **F 등급**: 0개 완료 (시작 상태)
- **E 등급**: 1-20개 완료
- **D 등급**: 21-40개 완료  
- **C 등급**: 41-60개 완료
- **B 등급**: 61-80개 완료
- **A 등급**: 81-100개 완료

## 🔧 개발 참고사항

### 데이터베이스 스키마

주요 테이블:
- `categories`: 스킬 카테고리
- `skills`: 스킬 정보
- `milestones`: 마일스톤 정보 (각 스킬당 100개)
- `profiles`: 사용자 프로필
- `user_milestones`: 사용자가 완료한 마일스톤

### 주요 함수

- `get_user_skill_progress()`: 특정 스킬의 사용자 진행상황 조회
- `get_user_all_skills_progress()`: 모든 스킬의 사용자 진행상황 조회

## 🎨 디자인 가이드

- **브랜드 컬러**: #1A237E (Material Design Indigo 900)
- **랭크별 컬러**:
  - F: 회색 (Grey)
  - E: 갈색 (Brown)  
  - D: 주황색 (Orange)
  - C: 노란색 (Yellow)
  - B: 하늘색 (Light Blue)
  - A: 보라색 (Purple)

## 📝 향후 개발 계획

- [ ] 스킬 추가 기능 (사용자 요청)
- [ ] 소셜 기능 (친구, 리더보드)
- [ ] 알림 시스템
- [ ] 통계 및 분석 기능
- [ ] 다크 모드 지원
- [ ] 다국어 지원

## 🐛 알려진 이슈

현재 알려진 주요 이슈는 없습니다.

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다.# Test deployment
