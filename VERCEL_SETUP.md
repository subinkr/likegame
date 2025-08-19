# Vercel GitHub Actions 설정 가이드

## 1. Vercel 토큰 생성

1. [Vercel Dashboard](https://vercel.com/account/tokens)에 접속
2. "Create Token" 클릭
3. 토큰 이름 입력 (예: "GitHub Actions")
4. 토큰 생성 후 복사

## 2. Vercel 프로젝트 정보 확인

### ORG_ID 확인
```bash
vercel teams ls
```
**현재 VERCEL_ORG_ID**: `likegame`

### PROJECT_ID 확인
```bash
vercel project inspect app
```
**현재 VERCEL_PROJECT_ID**: `prj_KDjqVq3mgeWQftUzlVxG08WxHyk2`

## 3. GitHub Secrets 설정

GitHub 저장소 → Settings → Secrets and variables → Actions에서 다음 설정:

### VERCEL_TOKEN
- Name: `VERCEL_TOKEN`
- Value: Vercel에서 생성한 토큰

### VERCEL_ORG_ID
- Name: `VERCEL_ORG_ID`
- Value: `likegame`

### VERCEL_PROJECT_ID
- Name: `VERCEL_PROJECT_ID`
- Value: `prj_KDjqVq3mgeWQftUzlVxG08WxHyk2`

## 4. 설정 확인

모든 Secrets가 설정되면 GitHub Actions가 자동으로 Vercel에 배포됩니다.

## 5. 수동 설정 명령어

```bash
# Vercel 로그인
vercel login

# 프로젝트 정보 확인
vercel projects ls

# 조직 정보 확인
vercel teams ls
```

## 6. 배포 URL

- 프로덕션 URL: https://app.likegame.life
- Vercel URL: https://app-i4jahvwb1-likegame.vercel.app
