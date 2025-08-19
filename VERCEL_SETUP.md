# Vercel GitHub Actions 설정 가이드

## 1. Vercel 토큰 생성

1. [Vercel Dashboard](https://vercel.com/account/tokens)에 접속
2. "Create Token" 클릭
3. 토큰 이름 입력 (예: "GitHub Actions")
4. 토큰 생성 후 복사

## 2. Vercel 프로젝트 정보

### ORG_ID
**VERCEL_ORG_ID**: `likegame`

### PROJECT_ID
**VERCEL_PROJECT_ID**: `prj_COmVFK363PyteH1fQdCIfsNERIRD`

## 3. GitHub Secrets 설정

GitHub 저장소 → Settings → Secrets and variables → Actions에서 다음 설정:

### VERCEL_TOKEN만 설정
- Name: `VERCEL_TOKEN`
- Value: Vercel에서 생성한 토큰

**참고**: 프로젝트 ID와 조직 ID는 워크플로우에 직접 하드코딩되어 있습니다.

## 4. 배포 방식

현재 설정된 배포 방식:
1. GitHub Actions에서 Flutter 웹 빌드
2. Vercel Action을 사용하여 빌드된 결과물 배포
3. `build/web` 디렉토리의 정적 파일들이 Vercel에 업로드

## 5. 설정 확인

VERCEL_TOKEN만 설정되면 GitHub Actions가 자동으로 Vercel에 배포됩니다.

## 6. 수동 설정 명령어

```bash
# Vercel 로그인
vercel login

# 프로젝트 정보 확인
vercel project inspect app --scope=likegame

# 조직 정보 확인
vercel teams ls
```

## 7. 배포 URL

- 프로덕션 URL: https://app-arh5hijhq-likegame.vercel.app
- 커스텀 도메인: https://app.likegame.life (설정 후)

## 8. 문제 해결

만약 "Project not found" 오류가 발생한다면:
1. Vercel 토큰이 올바른지 확인
2. 토큰이 `likegame` 조직의 `app` 프로젝트에 대한 접근 권한이 있는지 확인
3. GitHub Secrets에 `VERCEL_TOKEN`만 설정되어 있는지 확인
