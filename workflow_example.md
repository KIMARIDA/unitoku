# 실제 개발 워크플로우 예시

## 🔄 일반적인 하루 개발 사이클

### 1. 아침: 새로운 기능 개발 시작
```bash
# 새로운 기능 브랜치 생성 (선택사항)
git checkout -b feature/new-course-evaluation

# 코드 변경...
# (예: CourseEvaluationView.swift 수정)
```

### 2. 점심: 중간 테스트
```bash
# 빠른 확인용 빌드 (시뮬레이터에서 테스트 후)
./quick_build.sh

# 결과: build/unitoku_quick_YYYYMMDD_HHMMSS.xcarchive 생성
# → Xcode Organizer에서 확인 가능
```

### 3. 오후: 기능 완성 후 TestFlight 배포
```bash
# 변경사항 커밋
git add .
git commit -m "강의평가 기능 개선"

# 자동 TestFlight 배포
./build_and_upload.sh

# 5-10분 후 App Store Connect에서 새 빌드 확인
```

### 4. 저녁: 베타 테스터들에게 알림
- App Store Connect → TestFlight → 새 빌드 선택
- 테스터 그룹에 배포
- 변경사항 알림

## 📊 개발 주기별 배포 전략

### 매일 배포 (Agile)
- 작은 개선사항
- 버그 수정
- UI 미세 조정

### 주간 배포 (안정적)
- 새로운 기능
- 성능 개선
- 주요 변경사항

### 월간 배포 (정식 릴리즈)
- App Store 정식 출시
- 마케팅 버전 업데이트
