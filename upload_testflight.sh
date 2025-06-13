#!/bin/bash

# TestFlight Upload Script for unitoku
# This script uploads the most recent archive to TestFlight

set -e  # Exit on any error

echo "🚀 Starting TestFlight upload process..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="unitoku"
BUILD_DIR="./build"
APPLE_ID="rlawnsdyd4116@icloud.com"
TEAM_ID="82T2682DUV"

# Function to find the most recent archive
find_latest_archive() {
    local latest_archive=$(find "$BUILD_DIR" -name "*.xcarchive" -type d | sort -r | head -1)
    if [ -z "$latest_archive" ]; then
        echo -e "${RED}❌ No archives found in $BUILD_DIR${NC}"
        echo "Please run ./quick_build.sh first to create an archive."
        exit 1
    fi
    echo "$latest_archive"
}

# Function to upload to TestFlight with multiple authentication methods
upload_to_testflight() {
    local archive_path="$1"
    echo -e "${BLUE}📤 Uploading to TestFlight: $(basename "$archive_path")${NC}"
    
    # Method 1: Try with API key if available
    if [ -n "$API_KEY" ] && [ -n "$API_ISSUER" ]; then
        echo -e "${BLUE}🔑 Using App Store Connect API key authentication${NC}"
        if xcrun altool --upload-app \
            -f "$archive_path" \
            -t ios \
            --apiKey "$API_KEY" \
            --apiIssuer "$API_ISSUER" \
            --output-format normal; then
            return 0
        fi
        echo -e "${YELLOW}⚠️ API key authentication failed, trying alternative methods...${NC}"
    fi
    
    # Method 2: Try with keychain password
    echo -e "${BLUE}🔑 Trying keychain authentication${NC}"
    if xcrun altool --upload-app \
        -f "$archive_path" \
        -t ios \
        --username "$APPLE_ID" \
        --password "@keychain:AC_PASSWORD" \
        --output-format normal 2>/dev/null; then
        return 0
    fi
    
    # Method 3: Prompt for app-specific password
    echo -e "${YELLOW}⚠️ Keychain authentication failed.${NC}"
    echo -e "${BLUE}📱 You need an App-Specific Password for TestFlight upload.${NC}"
    echo ""
    echo -e "${YELLOW}To create an App-Specific Password:${NC}"
    echo "1. Go to https://appleid.apple.com/account/manage"
    echo "2. Sign in with your Apple ID: $APPLE_ID"
    echo "3. Go to 'App-Specific Passwords' section"
    echo "4. Generate a new password (name it 'TestFlight Upload')"
    echo "5. Copy the generated password"
    echo ""
    
    read -s -p "Enter your App-Specific Password: " APP_PASSWORD
    echo ""
    
    # Store in keychain for future use
    echo -e "${BLUE}💾 Storing password in keychain for future use...${NC}"
    xcrun altool --store-password-in-keychain-item "AC_PASSWORD" \
        --username "$APPLE_ID" \
        --password "$APP_PASSWORD" 2>/dev/null || true
    
    # Method 4: Upload with the provided password
    echo -e "${BLUE}📤 Uploading with app-specific password...${NC}"
    if xcrun altool --upload-app \
        -f "$archive_path" \
        -t ios \
        --username "$APPLE_ID" \
        --password "$APP_PASSWORD" \
        --output-format normal; then
        return 0
    fi
    
    echo -e "${RED}❌ All authentication methods failed${NC}"
    return 1
}

# Main execution
main() {
    echo -e "${BLUE}=== TestFlight Upload Tool ===${NC}"
    
    # Check for API key environment variables
    if [ -n "$APP_STORE_CONNECT_API_KEY" ] && [ -n "$APP_STORE_CONNECT_API_ISSUER" ]; then
        API_KEY="$APP_STORE_CONNECT_API_KEY"
        API_ISSUER="$APP_STORE_CONNECT_API_ISSUER"
        echo -e "${GREEN}✅ Found App Store Connect API credentials in environment${NC}"
    fi
    
    # Find the latest archive
    ARCHIVE_PATH=$(find_latest_archive)
    echo -e "${GREEN}📦 Found archive: $(basename "$ARCHIVE_PATH")${NC}"
    
    # Extract build info
    BUILD_NUMBER=$(defaults read "$ARCHIVE_PATH/Info.plist" ApplicationProperties | grep CFBundleVersion | cut -d'"' -f4 2>/dev/null || echo "Unknown")
    VERSION_NUMBER=$(defaults read "$ARCHIVE_PATH/Info.plist" ApplicationProperties | grep CFBundleShortVersionString | cut -d'"' -f4 2>/dev/null || echo "Unknown")
    
    echo -e "${BLUE}📋 Build Information:${NC}"
    echo "   Version: $VERSION_NUMBER"
    echo "   Build: $BUILD_NUMBER"
    echo "   Apple ID: $APPLE_ID"
    echo "   Team ID: $TEAM_ID"
    echo "   Archive: $(basename "$ARCHIVE_PATH")"
    echo ""
    
    # Confirm upload
    echo -e "${YELLOW}⚠️  This will upload to TestFlight for distribution.${NC}"
    read -p "Continue? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Upload cancelled.${NC}"
        exit 0
    fi
    
    # Upload to TestFlight
    if upload_to_testflight "$ARCHIVE_PATH"; then
        echo -e "${GREEN}🎉 Upload completed successfully!${NC}"
        echo -e "${BLUE}📱 Next steps:${NC}"
        echo "   1. Check App Store Connect for processing status"
        echo "   2. Once processed, distribute to TestFlight testers"
        echo "   3. Monitor crash reports and feedback"
        echo ""
        echo -e "${YELLOW}💡 Tip: Processing usually takes 5-15 minutes${NC}"
    else
        echo -e "${RED}❌ Upload failed${NC}"
        echo -e "${YELLOW}💡 Troubleshooting tips:${NC}"
        echo "   1. Verify your Apple ID and password"
        echo "   2. Check App Store Connect team membership"
        echo "   3. Ensure the app record exists in App Store Connect"
        echo "   4. Try creating an App-Specific Password"
        exit 1
    fi
}

# Run main function
main "$@"
