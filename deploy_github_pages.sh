#!/bin/bash

# Glist - GitHub Pages Deployment Script
# This script sets up and deploys privacy policy, terms, and support pages to GitHub Pages

echo "🚀 Glist - GitHub Pages Setup"
echo "=============================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -d "docs" ]; then
    echo -e "${YELLOW}⚠️  docs directory not found. Creating it...${NC}"
    mkdir -p docs
fi

echo -e "${BLUE}📁 Checking files...${NC}"
if [ -f "docs/index.html" ] && [ -f "docs/privacy.html" ] && [ -f "docs/terms.html" ] && [ -f "docs/support.html" ]; then
    echo -e "${GREEN}✅ All HTML files found${NC}"
else
    echo -e "${YELLOW}⚠️  Some HTML files are missing${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}🔧 Initializing Git repository (if needed)...${NC}"
if [ ! -d ".git" ]; then
    git init
    echo -e "${GREEN}✅ Git repository initialized${NC}"
else
    echo -e "${GREEN}✅ Git repository already exists${NC}"
fi

echo ""
echo -e "${BLUE}📝 Adding files to Git...${NC}"
git add docs/

echo ""
echo -e "${BLUE}💾 Committing changes...${NC}"
git commit -m "Add GitHub Pages documentation (privacy, terms, support)"

echo ""
echo -e "${GREEN}✅ Setup complete!${NC}"
echo ""
echo "=============================="
echo "📋 Next Steps:"
echo "=============================="
echo ""
echo "1. Create a GitHub repository (if you haven't already):"
echo "   - Go to https://github.com/new"
echo "   - Name: glist-app (or your preferred name)"
echo "   - Make it public"
echo "   - Don't initialize with README"
echo ""
echo "2. Connect your local repo to GitHub:"
echo "   git remote add origin https://github.com/YOUR_USERNAME/glist-app.git"
echo "   git branch -M main"
echo "   git push -u origin main"
echo ""
echo "3. Enable GitHub Pages:"
echo "   - Go to your repo → Settings → Pages"
echo "   - Source: Deploy from a branch"
echo "   - Branch: main"
echo "   - Folder: /docs"
echo "   - Click Save"
echo ""
echo "4. Your pages will be available at:"
echo "   https://YOUR_USERNAME.github.io/glist-app/privacy.html"
echo "   https://YOUR_USERNAME.github.io/glist-app/terms.html"
echo "   https://YOUR_USERNAME.github.io/glist-app/support.html"
echo ""
echo "5. Update App Store Connect with these URLs!"
echo ""
echo -e "${GREEN}🎉 Ready to deploy!${NC}"
