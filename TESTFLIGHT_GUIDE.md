# unitoku TestFlight 배포 가이드

## 📱 TestFlight 배포 과정

### 기본 원칙
- **새로운 기능/버그 수정 → 새로운 아카이브 필요**
- 각 TestFlight 빌드는 고유한 빌드 번호를 가져야 함
- Apple은 동일한 바이너리의 재업로드를 허용하지 않음

## 🚀 자동화된 배포 방법

### 1. 완전 자동 배포 (권장)
```bash
./build_and_upload.sh
```
- 빌드 번호 자동 증가
- 아카이브 생성
- TestFlight 자동 업로드
- Git 커밋 옵션

### 2. 빠른 빌드 (개발 중)
```bash
./quick_build.sh
```
- 빌드 번호 자동 증가
- 아카이브만 생성
- 수동 업로드 필요

### 3. 수동 빌드 (기존 방식)
```bash
xcodebuild archive \
    -project unitoku.xcodeproj \
    -scheme unitoku \
    -configuration Release \
    -destination "generic/platform=iOS" \
    -archivePath "./build/unitoku_manual.xcarchive" \
    CODE_SIGN_STYLE=Automatic \
    DEVELOPMENT_TEAM=82T2682DUV \
    -allowProvisioningUpdates
```

## 📋 개발 워크플로우 권장사항

### 일반적인 개발 사이클
1. **코드 변경** → `git commit`
2. **테스트** → `./quick_build.sh` (빠른 확인)
3. **배포 준비** → `./build_and_upload.sh` (자동 업로드)
4. **TestFlight 확인** → App Store Connect에서 테스터 배포

### 버전 관리 전략
- **Major 업데이트**: 큰 기능 추가 (1.0 → 2.0)
- **Minor 업데이트**: 작은 기능 추가 (1.0 → 1.1)
- **Patch 업데이트**: 버그 수정 (1.0.0 → 1.0.1)
- **Build 번호**: 자동 증가 (매번 +1)

## 🔧 트러블슈팅

### 일반적인 문제들

#### 1. 코드 사이닝 에러
```bash
# 해결: 자동 코드 사이닝 사용
CODE_SIGN_STYLE=Automatic
DEVELOPMENT_TEAM=82T2682DUV
```

#### 2. 빌드 번호 중복
```bash
# 해결: 스크립트가 자동으로 증가시킴
xcrun agvtool new-project-version $NEW_BUILD
```

#### 3. Firebase dSYM 업로드 실패
- 빌드 설정에서 이미 구성됨
- 자동으로 Crashlytics에 업로드됨

### 수동 빌드 번호 변경
```bash
# 현재 빌드 번호 확인
xcrun agvtool what-project-version

# 새로운 빌드 번호 설정
xcrun agvtool new-project-version 15
```

## 📱 App Store Connect 에서의 다음 단계

1. **App Store Connect 로그인**
2. **unitoku 앱 선택**
3. **TestFlight 탭**
4. **새로운 빌드 확인**
5. **테스터 그룹에 배포**
6. **테스트 정보 및 알림 작성**

## 💡 팁

### 개발 효율성 향상
- 작은 변경: `quick_build.sh` 사용
- 정식 배포: `build_and_upload.sh` 사용
- 정기적으로 TestFlight 빌드 정리

### 베타 테스트 모범 사례
- 명확한 테스트 지침 제공
- 변경 사항 목록 포함
- 피드백 수집 방법 안내
- 정기적인 업데이트 일정 유지

## 📁 생성되는 파일들
- `build/unitoku_testflight_YYYYMMDD_HHMMSS.xcarchive`
- `build/unitoku_quick_YYYYMMDD_HHMMSS.xcarchive` (빠른 빌드)
- 임시 `ExportOptions.plist` (자동 삭제됨)
