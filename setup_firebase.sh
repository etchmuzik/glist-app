#!/bin/bash

# Glist Firebase Database Setup Automation Script
# Following Firebase MCP initialization guides and best practices

set -e  # Exit on any error

echo "🔥 Complete Firebase Setup for Glist Project"
echo "Following Firebase MCP initialization order: Firestore → Auth → Rules → Storage"

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found. Installing..."
    npm install -g firebase-tools
fi

# 1. Login to Firebase (will prompt user)
echo "🔐 Step 1: Login to Firebase"
firebase login --no-localhost

# 2. Set project (verified from GoogleService-Info.plist)
echo "🎯 Step 2: Setting Firebase project to glist-6e64f"
firebase use glist-6e64f

# 3. Initialize Firestore (per MCP guide)
echo "📚 Step 3: Setting up Firestore database"
firebase projects:addfirebase --project glist-6e64f --yes
firebase services:enable firestore.googleapis.com --project glist-6e64f

# 4. Setup Authentication (per MCP guide)
echo "👤 Step 4: Setting up Firebase Authentication"
firebase services:enable identitytoolkit.googleapis.com --project glist-6e64f

# 5. Setup Storage
echo "🗂️  Step 5: Setting up Firebase Storage"
firebase services:enable storage.googleapis.com --project glist-6e64f

# 6. Deploy Firestore rules and indexes (per MCP guide)
echo "🔒 Step 6: Deploying Firestore security rules and indexes"
firebase deploy --only firestore:rules,firestore:indexes

# 7. Deploy Storage rules
echo "🔒 Step 7: Deploying Storage security rules"
firebase deploy --only storage

echo ""
echo "✅ Automated Firebase setup complete!"
echo ""
echo "📋 MANUAL STEPS REQUIRED:"
echo ""
echo "1. 🔐 Authentication Providers:"
echo "   - Go to: https://console.firebase.google.com/project/glist-6e64f/authentication/providers"
echo "   - Enable Email/Password provider"
echo "   - Add any additional auth methods (Google, Apple, etc.)"
echo ""
echo "2. 🔑 Service Account Key:"
echo "   - Go to: https://console.firebase.google.com/project/glist-6e64f/settings/serviceaccounts/adminsdk"
echo "   - Click 'Generate new private key'"
echo "   - Save as: serviceAccountKey.json (in project root)"
echo ""
echo "3. 🌱 Seed Database:"
echo "   After downloading serviceAccountKey.json, run:"
echo "   npm install firebase-admin uuid"
echo "   node seed_database.js"
echo ""
echo "4. 🧪 Verify Setup:"
echo "   - Visit: https://console.firebase.google.com/project/glist-6e64f/firestore"
echo "   - Test app's DatabaseSeedView functionality"
echo "   - Check DatabaseUpdateView for schema migrations"
echo ""
echo "⚠️  IMPORTANT: Complete steps 1-2 before running seed_database.js"
echo ""
echo "🎉 Ready to run your iOS app with full Firebase backend!"
