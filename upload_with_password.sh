#!/bin/bash

# TestFlight Upload with App-Specific Password
echo "=== TestFlight Upload ==="
echo "Archive: unitoku_fixed_20250613_115225.xcarchive (최신 성공 빌드)"
echo "Apple ID: rlawnsdyd4116@icloud.com"
echo "Note: 이미 App Store Connect에 업로드 완료됨 (2025-06-13 11:55)"
echo ""

# Prompt for app-specific password
echo "앱별 비밀번호를 입력하세요:"
echo "1. https://appleid.apple.com/account/manage 접속"
echo "2. '앱별 비밀번호' 섹션에서 새 비밀번호 생성"
echo "3. 이름: 'TestFlight Upload'"
echo "4. 생성된 비밀번호를 아래에 입력"
echo ""

read -s -p "앱별 비밀번호: " APP_PASSWORD
echo ""
echo "업로드 중..."

# Upload to TestFlight
xcrun altool --upload-app \
    -f "./build/unitoku_fixed_20250613_115225.xcarchive" \
    -t ios \
    -u "rlawnsdyd4116@icloud.com" \
    --password "$APP_PASSWORD"

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 업로드 성공!"
    echo "App Store Connect에서 처리 상태를 확인하세요."
    echo "처리 완료 후 TestFlight에서 테스터들에게 배포할 수 있습니다."
else
    echo ""
    echo "❌ 업로드 실패"
    echo "앱별 비밀번호가 올바른지 확인하세요."
fi
