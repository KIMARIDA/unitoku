#!/bin/bash

# Firebase Crashlytics dSYM upload script
# This script uploads dSYM files to Firebase Crashlytics for crash symbolication

# Check if the required environment variables are set
if [ -z "$DWARF_DSYM_FOLDER_PATH" ] || [ -z "$DWARF_DSYM_FILE_NAME" ]; then
    echo "Warning: dSYM environment variables not set. Skipping dSYM upload."
    exit 0
fi

# Path to the dSYM file
DSYM_PATH="${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}"

if [ ! -d "$DSYM_PATH" ]; then
    echo "Warning: dSYM file not found at $DSYM_PATH. Skipping upload."
    exit 0
fi

echo "Uploading dSYM file: $DSYM_PATH"

# Firebase Crashlytics upload using Swift Package Manager binary
# Find the Firebase Crashlytics upload-symbols script
FIREBASE_SCRIPT=""
if [ -n "$BUILD_DIR" ]; then
    # Try to find the upload-symbols script in DerivedData
    DERIVED_DATA_DIR="$(dirname "$BUILD_DIR")"
    FIREBASE_SCRIPT=$(find "$DERIVED_DATA_DIR" -name "upload-symbols" -path "*/firebase-ios-sdk/Crashlytics/upload-symbols" 2>/dev/null | head -1)
    if [ -z "$FIREBASE_SCRIPT" ]; then
        FIREBASE_SCRIPT=$(find "$DERIVED_DATA_DIR" -name "upload-symbols" -path "*/FirebaseCrashlytics/*" 2>/dev/null | head -1)
    fi
fi

# Fallback to project's DerivedData directory
if [ -z "$FIREBASE_SCRIPT" ] && [ -n "$PROJECT_DIR" ]; then
    FIREBASE_SCRIPT=$(find "$PROJECT_DIR/DerivedData" -name "upload-symbols" -path "*/firebase-ios-sdk/Crashlytics/upload-symbols" 2>/dev/null | head -1)
    if [ -z "$FIREBASE_SCRIPT" ]; then
        FIREBASE_SCRIPT=$(find "$PROJECT_DIR/DerivedData" -name "upload-symbols" -path "*/FirebaseCrashlytics/*" 2>/dev/null | head -1)
    fi
fi

# Final fallback - search in the most common location
if [ -z "$FIREBASE_SCRIPT" ]; then
    FIREBASE_SCRIPT=$(find ~/Library/Developer/Xcode/DerivedData -name "upload-symbols" -path "*/firebase-ios-sdk/Crashlytics/upload-symbols" 2>/dev/null | head -1)
    if [ -z "$FIREBASE_SCRIPT" ]; then
        FIREBASE_SCRIPT=$(find ~/Library/Developer/Xcode/DerivedData -name "upload-symbols" -path "*/FirebaseCrashlytics/*" 2>/dev/null | head -1)
    fi
fi

if [ -n "$FIREBASE_SCRIPT" ] && [ -f "$FIREBASE_SCRIPT" ]; then
    echo "Found Firebase upload script at: $FIREBASE_SCRIPT"
    "$FIREBASE_SCRIPT" -gsp "${PROJECT_DIR}/unitoku/GoogleService-Info.plist" -p ios "${DSYM_PATH}"
else
    echo "Error: Firebase Crashlytics upload-symbols script not found"
    echo "Make sure Firebase Crashlytics is properly installed via Swift Package Manager"
    exit 1
fi

if [ $? -eq 0 ]; then
    echo "dSYM upload successful"
else
    echo "dSYM upload failed"
fi
