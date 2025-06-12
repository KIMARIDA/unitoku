# TestFlight 자동화를 위한 GitHub Actions Secrets 설정

GitHub Actions를 사용한 자동화된 TestFlight 배포를 설정하려면 GitHub 저장소에서 다음 secrets를 구성해야 합니다:

## 필수 Secrets

### 1. 코드 서명 인증서
**Secret 이름:** `BUILD_CERTIFICATE_BASE64`
**설명:** base64 형식의 Apple Distribution 인증서

**얻는 방법:**
```bash
# 키체인에서 인증서를 .p12 파일로 내보내기
# 그 다음 base64로 변환:
base64 -i YourCertificate.p12 | pbcopy
```

### 2. 인증서 비밀번호
**Secret 이름:** `P12_PASSWORD`
**설명:** .p12 인증서 파일의 비밀번호

### 3. 키체인 비밀번호
**Secret 이름:** `KEYCHAIN_PASSWORD`
**설명:** 임시 키체인용 보안 비밀번호 (무작위로 생성 가능)

### 4. 프로비저닝 프로파일
**Secret 이름:** `PROVISIONING_CERTIFICATE_BASE64`
**설명:** base64 형식의 App Store 프로비저닝 프로파일

**얻는 방법:**
```bash
# Apple Developer 포털에서 다운로드 후:
base64 -i YourProfile.mobileprovision | pbcopy
```

### 5. Team ID
**Secret 이름:** `TEAM_ID`
**설명:** Apple Developer Team ID
**값:** `82T2682DUV` (빌드 스크립트 기반)

### 6. App Store Connect API Key ID
**Secret 이름:** `APPSTORE_CONNECT_API_KEY_ID`
**설명:** App Store Connect API 키의 Key ID

### 7. App Store Connect Issuer ID
**Secret 이름:** `APPSTORE_CONNECT_ISSUER_ID`
**설명:** App Store Connect의 Issuer ID

### 8. App Store Connect API Key
**Secret 이름:** `APPSTORE_CONNECT_API_KEY_BASE64`
**설명:** base64 형식의 App Store Connect API 키 (.p8 파일)

**App Store Connect API 자격증명 얻는 방법:**
1. App Store Connect → 사용자 및 액세스 → 키로 이동
2. "개발자" 역할로 새 키 생성
3. .p8 파일 다운로드
4. Key ID 및 Issuer ID 기록
5. .p8를 base64로 변환:
```bash
base64 -i AuthKey_XXXXXXXXXX.p8 | pbcopy
```

## GitHub에서 Secrets 설정하기

1. GitHub 저장소로 이동
2. "Settings" → "Secrets and variables" → "Actions" 클릭
3. 각 secret에 대해 "New repository secret" 클릭
4. 정확한 이름과 값으로 모든 secrets 추가

## 워크플로우 트리거

GitHub Action은 다음 경우에 자동 실행됩니다:
- `main` 브랜치에 푸시할 때
- 새 태그 생성 시 (예: `v1.0.1`)
- Actions 탭에서 수동으로 트리거할 때

## 수동 트리거

빌드를 수동으로 트리거하려면:
1. GitHub → Actions → "TestFlight Deployment"로 이동
2. "Run workflow" 클릭
3. 브랜치와 버전 범프 유형 선택
4. "Run workflow" 클릭

## 보안 참고사항

- 저장소에 인증서나 API 키를 절대 커밋하지 마세요
- 모든 민감한 정보는 GitHub Secrets를 사용하세요
- App Store Connect API 키를 정기적으로 교체하세요
- CI/CD와 로컬 개발용으로 별도 인증서 사용을 고려하세요

## 문제 해결

일반적인 문제와 해결책:

1. **코드 서명 실패**
   - 인증서와 프로비저닝 프로파일이 올바른지 확인
   - Team ID가 Apple Developer 계정과 일치하는지 확인

2. **업로드 인증 실패**
   - App Store Connect API 키 자격증명 확인
   - API 키가 "개발자" 역할 권한을 가지고 있는지 확인

3. **프로비저닝 프로파일 문제**
   - 프로파일이 번들 ID 및 인증서와 일치하는지 확인
   - 프로파일이 만료되지 않았는지 확인

## 다음 단계

secrets 설정 완료 후:
1. 작은 변경사항으로 워크플로우 테스트
2. 빌드 상태를 위해 Actions 탭 모니터링
3. 성공적인 업로드를 위해 App Store Connect 확인
4. 배포를 위한 TestFlight 테스터 그룹 설정
