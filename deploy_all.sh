#!/bin/bash

# Complete Firebase Deployment Script
# Deploys all Firebase services following MCP guidelines

set -e

echo "🚀 Deploying all Firebase services for Glist project..."

# Full deploy including all services
npx firebase-tools@latest deploy --non-interactive

echo ""
echo "✅ All Firebase services deployed successfully!"
echo ""
echo "📊 Services Deployed:"
echo "   - Firestore Database & Security Rules"
echo "   - Cloud Storage & Security Rules"
echo "   - Firebase Hosting (if configured)"
echo ""
echo "🔍 Check deployment status:"
echo "   https://console.firebase.google.com/project/glist-6e64f/overview"
