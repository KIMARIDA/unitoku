#!/bin/bash

# unitoku 빠른 TestFlight 빌드 스크립트 (개발 중 테스트용)
# 사용법: ./quick_build.sh

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 프로젝트 설정
PROJECT_DIR="/Users/junnykim/unitoku"
PROJECT_NAME="unitoku"
SCHEME="unitoku"
CONFIGURATION="Release"
TEAM_ID="82T2682DUV"

echo -e "${BLUE}⚡ unitoku 빠른 빌드 시작${NC}"

cd "$PROJECT_DIR"

# 빌드 번호만 자동 증가
CURRENT_BUILD=$(xcodebuild -project "$PROJECT_NAME.xcodeproj" -showBuildSettings -configuration "$CONFIGURATION" | grep "CURRENT_PROJECT_VERSION" | head -1 | sed 's/.*= //')
NEW_BUILD=$((CURRENT_BUILD + 1))

echo -e "${YELLOW}🔧 빌드 번호: $CURRENT_BUILD → $NEW_BUILD${NC}"
xcrun agvtool new-version $NEW_BUILD

# 아카이브만 생성 (업로드는 수동)
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
ARCHIVE_PATH="./build/${PROJECT_NAME}_quick_${TIMESTAMP}.xcarchive"

echo -e "${YELLOW}📦 아카이브 생성 중...${NC}"

xcodebuild archive \
    -project "$PROJECT_NAME.xcodeproj" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -destination "generic/platform=iOS" \
    -archivePath "$ARCHIVE_PATH" \
    CODE_SIGN_STYLE=Automatic \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    -allowProvisioningUpdates

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ 빠른 빌드 완료!${NC}"
    echo -e "${YELLOW}📁 아카이브 위치: $ARCHIVE_PATH${NC}"
    echo -e "${BLUE}💡 Xcode Organizer에서 수동으로 업로드하거나 ./build_and_upload.sh를 사용하세요${NC}"
else
    echo -e "${RED}❌ 빌드 실패${NC}"
    exit 1
fi
