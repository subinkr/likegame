# 배포 설정 가이드

## Vercel 배포 설정

### 1. Vercel 토큰 생성
1. [Vercel Dashboard](https://vercel.com/account/tokens)에 접속
2. "Create Token" 클릭
3. 토큰 이름: "GitHub Actions"
4. 토큰 생성 후 복사

### 2. GitHub Secrets 설정
GitHub 저장소 → Settings → Secrets and variables → Actions에서:

**VERCEL_TOKEN**
- Name: `VERCEL_TOKEN`
- Value: Vercel에서 생성한 토큰

### 3. 프로젝트 정보
- **조직 ID**: `likegame`
- **프로젝트 ID**: `prj_EPiP239uLGIAtj4sm4h4YxkSa1k8`
- **배포 URL**: https://likegame-3u0lyl2kj-likegame.vercel.app

### 4. 배포 방식
1. main 브랜치에 푸시하면 자동으로 GitHub Actions가 실행됩니다
2. Flutter 웹 앱을 빌드합니다
3. Vercel에 배포합니다

### 5. 설정 완료 후
GitHub에 푸시하면 자동으로 Vercel에 배포됩니다.
