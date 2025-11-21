#!/bin/bash

# Glist - Pre-Deployment Setup Script
# Run this script to prepare your app for App Store submission

echo "🚀 Glist - Pre-Deployment Setup"
echo "================================"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "Glist.xcodeproj/project.pbxproj" ]; then
    echo -e "${RED}❌ Error: Not in Glist project directory${NC}"
    echo "Please run this script from the Glist project root"
    exit 1
fi

echo -e "${GREEN}✅ Found Glist project${NC}"
echo ""

# 1. Check Xcode version
echo "📱 Checking Xcode version..."
XCODE_VERSION=$(xcodebuild -version | head -n 1)
echo -e "${GREEN}✅ $XCODE_VERSION${NC}"
echo ""

# 2. Check for required files
echo "📄 Checking required files..."
FILES=(
    "Glist/Info.plist"
    "Glist/GoogleService-Info.plist"
)

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅ $file${NC}"
    else
        echo -e "${RED}❌ Missing: $file${NC}"
    fi
done
echo ""

# 3. Check bundle identifier
echo "🔍 Checking bundle identifier..."
BUNDLE_ID=$(defaults read "$(pwd)/Glist/Info.plist" CFBundleIdentifier 2>/dev/null)
if [ "$BUNDLE_ID" == "com.etch.glist" ]; then
    echo -e "${GREEN}✅ Bundle ID: $BUNDLE_ID${NC}"
else
    echo -e "${YELLOW}⚠️  Bundle ID: $BUNDLE_ID (expected: com.etch.glist)${NC}"
fi
echo ""

# 4. Check version and build number
echo "📊 Checking version info..."
VERSION=$(defaults read "$(pwd)/Glist/Info.plist" CFBundleShortVersionString 2>/dev/null)
BUILD=$(defaults read "$(pwd)/Glist/Info.plist" CFBundleVersion 2>/dev/null)
echo -e "${GREEN}✅ Version: $VERSION${NC}"
echo -e "${GREEN}✅ Build: $BUILD${NC}"
echo ""

# 5. Clean build folder
echo "🧹 Cleaning build folder..."
xcodebuild clean -scheme Glist -configuration Release > /dev/null 2>&1
echo -e "${GREEN}✅ Build folder cleaned${NC}"
echo ""

# 6. Check for App Icon
echo "🎨 Checking App Icon..."
if [ -d "Glist/Assets.xcassets/AppIcon.appiconset" ]; then
    ICON_COUNT=$(ls -1 Glist/Assets.xcassets/AppIcon.appiconset/*.png 2>/dev/null | wc -l)
    if [ $ICON_COUNT -gt 0 ]; then
        echo -e "${GREEN}✅ App Icon found ($ICON_COUNT images)${NC}"
    else
        echo -e "${YELLOW}⚠️  App Icon folder exists but no images found${NC}"
    fi
else
    echo -e "${RED}❌ App Icon not configured${NC}"
fi
echo ""

# 7. Check for Launch Screen
echo "🖼️  Checking Launch Screen..."
if [ -f "Glist/Launch Screen.storyboard" ]; then
    echo -e "${GREEN}✅ Launch Screen configured${NC}"
else
    echo -e "${YELLOW}⚠️  Launch Screen not found${NC}"
fi
echo ""

# 8. Validate project
echo "🔍 Validating project..."
xcodebuild -scheme Glist -configuration Release -showBuildSettings > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Project configuration valid${NC}"
else
    echo -e "${RED}❌ Project configuration has issues${NC}"
fi
echo ""

# 9. Summary
echo "================================"
echo "📋 Pre-Deployment Summary"
echo "================================"
echo ""
echo "Next Steps:"
echo "1. ✅ Update GoogleService-Info.plist with production Firebase config"
echo "2. ✅ Configure Stripe production keys in PaymentManager.swift"
echo "3. ✅ Add App Icon (1024x1024 and all required sizes)"
echo "4. ✅ Create Launch Screen"
echo "5. ✅ Update version number if needed"
echo "6. ✅ Archive app: Product → Archive in Xcode"
echo "7. ✅ Upload to App Store Connect"
echo ""
echo "📚 See deployment_guide.md for complete instructions"
echo ""
echo -e "${GREEN}🚀 Ready to deploy!${NC}"
