# unitoku TestFlight 자동화 가이드

## 📱 현재 상태

unitoku 앱의 TestFlight 배포 프로세스가 완전히 자동화되었습니다!

### ✅ 설정 완료된 내용
- **자동 빌드 스크립트**: 빌드 번호 자동 증가, 아카이브 생성
- **App Store Connect 업로드**: 완전 자동화된 TestFlight 배포
- **Firebase Crashlytics**: dSYM 자동 업로드로 크래시 추적
- **GitHub Actions**: CI/CD 파이프라인 (설정 가능)

### 📊 현재 앱 정보
- **마케팅 버전**: 1.0
- **빌드 번호**: 2 (자동 증가됨)
- **번들 ID**: com.junnykim.unitoku
- **Team ID**: 82T2682DUV

## 🚀 빠른 시작 가이드

### 1. 로컬 개발 빌드
```bash
# 빠른 개발 테스트용 빌드
./quick_build.sh
```

### 2. TestFlight 배포
```bash
# 완전한 프로덕션 배포 (한국어 인터페이스)
./build_and_upload.sh
```

### 3. 기존 아카이브 업로드
```bash
# 가장 최근 아카이브를 App Store Connect에 업로드
./upload_to_appstore.sh
```

## 📋 TestFlight 배포 체크리스트

### 배포 전 확인사항
- [ ] 코드 변경사항 완료 및 테스트
- [ ] Firebase 설정 확인 (GoogleService-Info.plist)
- [ ] 앱 아이콘 및 리소스 최신화
- [ ] 인증서 및 프로비저닝 프로파일 유효성 확인

### 배포 과정
- [ ] `./build_and_upload.sh` 실행
- [ ] Git 상태 확인 및 커밋 여부 결정
- [ ] 빌드 번호 자동 증가 확인
- [ ] 아카이브 생성 성공 확인
- [ ] App Store Connect 업로드 완료

### 배포 후 확인사항
- [ ] App Store Connect에서 처리 상태 확인 (5-15분 소요)
- [ ] TestFlight에서 빌드 활성화
- [ ] 내부 테스터에게 배포
- [ ] "테스트할 내용" 노트 작성
- [ ] 외부 테스터 배포 (필요시)

## 🔧 고급 설정

### GitHub Actions 자동화
1. `GITHUB_SECRETS_SETUP.md` 참조하여 secrets 설정
2. 코드 푸시 시 자동 TestFlight 배포
3. 태그 생성 시 릴리스 노트 자동 생성

### Firebase Crashlytics
- dSYM 파일 자동 업로드 활성화됨
- 크래시 발생 시 실시간 알림
- 성능 모니터링 데이터 수집

### 다국어 지원
- 현재 지원 언어: 일본어(ja), 한국어(ko), 영어(en)
- `Localizable.xcstrings` 파일로 관리
- 새 언어 추가 시 프로젝트 설정에서 추가

## 📱 TestFlight 테스터 관리

### 내부 테스터 (즉시 사용 가능)
- 팀 멤버 최대 100명
- App Store Connect에서 초대
- 빌드 업로드 즉시 접근 가능

### 외부 테스터 (Apple 검토 필요)
- 일반 사용자 최대 10,000명
- Apple 검토 24-48시간 소요
- 공개 링크 또는 이메일 초대

## 🛠️ 문제 해결

### 빌드 실패 시
1. Xcode에서 수동 빌드 테스트
2. 인증서 및 프로비저닝 프로파일 확인
3. Firebase 설정 파일 존재 확인
4. 의존성 라이브러리 업데이트

### 업로드 실패 시
1. 인터넷 연결 상태 확인
2. Apple Developer 계정 상태 확인
3. App Store Connect API 키 유효성 확인
4. 아카이브 파일 무결성 검증

### 코드 서명 문제
1. Xcode → Preferences → Accounts에서 계정 확인
2. Automatically manage signing 활성화
3. Team ID가 올바른지 확인
4. 인증서 만료일 확인

## 📈 성능 모니터링

### Firebase Analytics
- 사용자 행동 패턴 추적
- 앱 성능 지표 모니터링
- 사용자 세그먼트 분석

### Crashlytics
- 실시간 크래시 보고
- 성능 이슈 감지
- 사용자 영향도 분석

## 🎯 다음 단계

### 단기 목표
1. 첫 번째 TestFlight 빌드 배포
2. 내부 테스터 그룹 구성
3. 초기 피드백 수집

### 중기 목표
1. 외부 베타 테스트 시작
2. GitHub Actions CI/CD 설정
3. 자동화된 테스트 추가

### 장기 목표
1. App Store 제출 준비
2. 프로덕션 릴리스 계획
3. 지속적인 업데이트 스케줄

## 📞 지원 및 참고자료

### 문서
- `TESTFLIGHT_AUTOMATION.md` - 상세 스크립트 가이드
- `GITHUB_SECRETS_SETUP.md` - CI/CD 설정 가이드

### Apple 리소스
- [App Store Connect 가이드](https://developer.apple.com/app-store-connect/)
- [TestFlight 문서](https://developer.apple.com/testflight/)
- [코드 서명 가이드](https://developer.apple.com/support/code-signing/)

### Firebase 리소스
- [Firebase iOS 설정](https://firebase.google.com/docs/ios/setup)
- [Crashlytics 구현](https://firebase.google.com/docs/crashlytics/get-started)

---

🎉 **축하합니다!** unitoku 앱의 TestFlight 배포 시스템이 완전히 설정되었습니다. 이제 몇 번의 클릭만으로 새로운 빌드를 테스터들에게 배포할 수 있습니다!
