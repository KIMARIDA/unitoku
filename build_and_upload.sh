#!/bin/bash

# unitoku TestFlight 自動ビルド・アップロードスクリプト
# 使用法: ./build_and_upload.sh [バージョン増加タイプ]
# 例: ./build_and_upload.sh patch (1.0.1 -> 1.0.2)
# 例: ./build_and_upload.sh minor (1.0.1 -> 1.1.0)

set -e  # エラー時にスクリプト中断

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# プロジェクト設定
PROJECT_DIR="/Users/junnykim/unitoku"
PROJECT_NAME="unitoku"
SCHEME="unitoku"
CONFIGURATION="Release"
TEAM_ID="82T2682DUV"
BUNDLE_ID="com.junnykim.unitoku"

echo -e "${BLUE}🚀 unitoku TestFlight 自動デプロイ開始${NC}"

# プロジェクトディレクトリに移動
cd "$PROJECT_DIR"

# 1. Git状態確認
echo -e "${YELLOW}📋 Git状態確認中...${NC}"
if ! git diff-index --quiet HEAD --; then
    echo -e "${RED}⚠️  コミットされていない変更があります。先にコミットしてください。${NC}"
    git status --porcelain
    read -p "続行しますか？ (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# 2. 現在のバージョン情報取得
echo -e "${YELLOW}📝 現在のバージョン情報確認中...${NC}"
CURRENT_VERSION=$(xcodebuild -project "$PROJECT_NAME.xcodeproj" -showBuildSettings -configuration "$CONFIGURATION" | grep "MARKETING_VERSION" | head -1 | sed 's/.*= //')
CURRENT_BUILD=$(xcodebuild -project "$PROJECT_NAME.xcodeproj" -showBuildSettings -configuration "$CONFIGURATION" | grep "CURRENT_PROJECT_VERSION" | head -1 | sed 's/.*= //')

echo -e "現在のバージョン: ${GREEN}$CURRENT_VERSION${NC}"
echo -e "現在のビルド: ${GREEN}$CURRENT_BUILD${NC}"

# 3. ビルド番号自動増加
NEW_BUILD=$((CURRENT_BUILD + 1))
echo -e "新しいビルド番号: ${GREEN}$NEW_BUILD${NC}"

# 4. ビルド番号更新
echo -e "${YELLOW}🔧 ビルド番号更新中...${NC}"
xcrun agvtool new-version $NEW_BUILD

# 5. プロジェクトクリーン
echo -e "${YELLOW}🧹 プロジェクトクリーン中...${NC}"
xcodebuild clean -project "$PROJECT_NAME.xcodeproj" -scheme "$SCHEME" -configuration "$CONFIGURATION"

# 6. アーカイブ作成
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
ARCHIVE_PATH="./build/${PROJECT_NAME}_testflight_${TIMESTAMP}.xcarchive"

echo -e "${YELLOW}📦 アーカイブ作成中...${NC}"
echo -e "アーカイブパス: ${BLUE}$ARCHIVE_PATH${NC}"

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
    echo -e "${GREEN}✅ アーカイブ作成成功！${NC}"
else
    echo -e "${RED}❌ アーカイブ作成失敗${NC}"
    exit 1
fi

# 7. App Store Connect アップロード用ExportOptions.plist作成
EXPORT_OPTIONS_PATH="./ExportOptions.plist"
cat > "$EXPORT_OPTIONS_PATH" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>$TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
    <key>destination</key>
    <string>upload</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
</dict>
</plist>
EOF

# 8. IPA作成・アップロード
IPA_PATH="./build/${PROJECT_NAME}_testflight_${TIMESTAMP}.ipa"

echo -e "${YELLOW}📤 App Store Connect アップロード中...${NC}"
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "./build/" \
    -exportOptionsPlist "$EXPORT_OPTIONS_PATH" \
    -allowProvisioningUpdates

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ TestFlight アップロード成功！${NC}"
    echo -e "${BLUE}🎉 新しいビルド ($CURRENT_VERSION build $NEW_BUILD) がTestFlightにアップロードされました！${NC}"
    echo -e "${YELLOW}📱 App Store Connectでテスターに配布できます。${NC}"
    
    # アップロードファイル整理
    rm -f "$EXPORT_OPTIONS_PATH"
    
    # Gitにバージョン変更をコミット（オプション）
    read -p "バージョン変更をGitにコミットしますか？ (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git add .
        git commit -m "Bump build version to $NEW_BUILD for TestFlight"
        echo -e "${GREEN}✅ Git コミット完了${NC}"
    fi
    
else
    echo -e "${RED}❌ TestFlight アップロード失敗${NC}"
    rm -f "$EXPORT_OPTIONS_PATH"
    exit 1
fi

echo -e "${BLUE}🏁 TestFlight デプロイ完了！${NC}"
