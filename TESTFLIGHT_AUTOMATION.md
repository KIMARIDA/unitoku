# unitoku TestFlight 관리 스크립트

## 사용 가능한 스크립트

### 1. `quick_build.sh` - 빠른 개발 빌드
```bash
./quick_build.sh
```
- 개발 테스트용 빠른 빌드 및 아카이브
- 빌드 번호 자동 증가
- 타임스탬프가 포함된 아카이브 생성
- Firebase Crashlytics dSYM 업로드 포함

### 2. `build_and_upload.sh` - 완전한 TestFlight 파이프라인
```bash
./build_and_upload.sh
```
- 전체 프로덕션 파이프라인
- Git 상태 검증
- 빌드 번호 자동 증가
- 아카이브 생성 및 App Store Connect 업로드
- 버전 변경사항 Git 커밋 옵션
- 한국어 인터페이스

### 3. `upload_to_appstore.sh` - 기존 아카이브 업로드
```bash
./upload_to_appstore.sh
```
- 가장 최근 아카이브를 App Store Connect에 업로드
- 업로드 전 아카이브 검증
- 상세한 피드백 및 다음 단계 안내

## TestFlight 워크플로우

### 1단계: 개발 → 아카이브
1. 코드 변경사항 완료
2. 시뮬레이터 및 실제 기기에서 철저한 테스트
3. 빠른 테스트 빌드는 `./quick_build.sh` 실행
4. TestFlight 배포는 `./build_and_upload.sh` 실행

### 2단계: App Store Connect 처리
1. 업로드 후 App Store Connect 확인
2. 처리 시간은 보통 5-15분 소요
3. 준비 완료 시 이메일 확인 받음

### 3단계: TestFlight 배포
1. App Store Connect 로그인
2. "TestFlight" 섹션으로 이동
3. 앱 선택 → 최신 빌드
4. 내부/외부 테스터 추가
5. "테스트할 내용" 노트 제공
6. 테스트 제출

### 4단계: 테스터 관리
- **내부 테스터**: 최대 100명의 팀 멤버, 즉시 접근 가능
- **외부 테스터**: 최대 10,000명 사용자, Apple 검토 필요 (24-48시간)

## 빌드 번호 관리

스크립트는 빌드 번호를 자동으로 처리합니다:
- 마케팅 버전: `1.0` (Xcode에서 수동 설정)
- 빌드 번호: 자동 증가 (1, 2, 3, 등)

## 문제 해결

### 일반적인 문제들:
1. **아카이브 검증 실패**
   - 프로비저닝 프로파일 확인
   - 코드 서명 설정 검증
   - 모든 프레임워크가 올바르게 포함되었는지 확인

2. **업로드 인증 오류**
   - App Store Connect API 키 사용 (권장)
   - 또는 Apple ID용 앱별 비밀번호 설정

3. **dSYM 파일 누락**
   - "Debug Information Format" → "DWARF with dSYM File" 활성화
   - Crashlytics 업로드는 자동으로 처리됨

### App Store Connect API 키 설정:
1. App Store Connect → 사용자 및 액세스 → 키
2. "개발자" 역할로 새 키 생성
3. `.p8` 파일 다운로드
4. `xcrun altool --apiKey` 옵션과 함께 사용

## 자동화 팁

### CI/CD 통합을 위해:
1. App Store Connect API 키 인증 사용
2. 민감한 데이터를 환경 변수에 저장
3. 코드 푸시 시 자동 빌드 설정
4. GitHub Actions 또는 Xcode Cloud 사용 고려

### 버전 관리:
- 마케팅 버전에 시맨틱 버전 관리 사용
- 빌드 번호 증가는 스크립트가 처리하도록 함
- 추적을 위해 Git에서 릴리스 태그 설정

## 다음 단계

1. **GitHub Actions로 자동화된 CI/CD 설정**
2. **다양한 사용자 유형별 TestFlight 그룹 구성**
3. **크래시 리포팅 모니터링 설정**
4. **App Store 제출 워크플로우 계획**

## 생성된 파일들:
- `quick_build.sh` - 개발 빌드
- `upload_to_appstore.sh` - 업로드 도우미
- `build_and_upload.sh` - 완전한 파이프라인
- `build/` - 아카이브 저장 디렉토리
