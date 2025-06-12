#!/bin/bash

# Upload to App Store Connect Script for unitoku
# This script uploads the most recent archive to App Store Connect for TestFlight distribution

set -e  # Exit on any error

echo "🚀 Starting App Store Connect upload process..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="unitoku"
BUILD_DIR="./build"
SCHEME_NAME="unitoku"

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

# Function to validate archive
validate_archive() {
    local archive_path="$1"
    echo -e "${BLUE}🔍 Validating archive: $(basename "$archive_path")${NC}"
    
    if ! xcrun altool --validate-app \
        -f "$archive_path" \
        -t ios \
        --output-format xml; then
        echo -e "${RED}❌ Archive validation failed${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Archive validation successful${NC}"
}

# Function to upload to App Store Connect
upload_archive() {
    local archive_path="$1"
    echo -e "${BLUE}📤 Uploading to App Store Connect: $(basename "$archive_path")${NC}"
    
    # Note: This requires your Apple ID and app-specific password
    # You can set these as environment variables or use Keychain
    if ! xcrun altool --upload-app \
        -f "$archive_path" \
        -t ios \
        --output-format xml; then
        echo -e "${RED}❌ Upload failed${NC}"
        echo -e "${YELLOW}💡 Make sure you have:"
        echo "   1. Valid Apple Developer account"
        echo "   2. App-specific password configured"
        echo "   3. Proper provisioning profiles"
        echo "   4. App Store Connect record created${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Upload successful!${NC}"
}

# Main execution
main() {
    echo -e "${BLUE}=== App Store Connect Upload Tool ===${NC}"
    
    # Find the latest archive
    ARCHIVE_PATH=$(find_latest_archive)
    echo -e "${GREEN}📦 Found archive: $(basename "$ARCHIVE_PATH")${NC}"
    
    # Extract build info
    BUILD_NUMBER=$(defaults read "$ARCHIVE_PATH/Info.plist" ApplicationProperties | grep CFBundleVersion | cut -d'"' -f4)
    VERSION_NUMBER=$(defaults read "$ARCHIVE_PATH/Info.plist" ApplicationProperties | grep CFBundleShortVersionString | cut -d'"' -f4)
    
    echo -e "${BLUE}📋 Build Information:${NC}"
    echo "   Version: $VERSION_NUMBER"
    echo "   Build: $BUILD_NUMBER"
    echo "   Archive: $(basename "$ARCHIVE_PATH")"
    echo ""
    
    # Confirm upload
    echo -e "${YELLOW}⚠️  This will upload to App Store Connect for TestFlight distribution.${NC}"
    read -p "Continue? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Upload cancelled.${NC}"
        exit 0
    fi
    
    # Validate before upload
    validate_archive "$ARCHIVE_PATH"
    
    # Upload to App Store Connect
    upload_archive "$ARCHIVE_PATH"
    
    echo -e "${GREEN}🎉 Process completed successfully!${NC}"
    echo -e "${BLUE}📱 Next steps:${NC}"
    echo "   1. Check App Store Connect for processing status"
    echo "   2. Once processed, distribute to TestFlight testers"
    echo "   3. Monitor crash reports and feedback"
    echo ""
    echo -e "${YELLOW}💡 Tip: Processing usually takes 5-15 minutes${NC}"
}

# Run main function
main "$@"
