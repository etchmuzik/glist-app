# Firebase Database Setup Automation for Glist

This directory contains automated scripts to set up Firebase/Firestore for the Glist iOS app.

## Files Created

- `firebase.json` - Firebase project configuration
- `firestore.rules` - Firestore security rules for all collections
- `storage.rules` - Firebase Storage security rules
- `firestore.indexes.json` - Database indexes for optimized queries
- `setup_firebase.sh` - Automated Firebase CLI setup script
- `seed_database.js` - Node.js script to populate initial venue data

## Collections Setup

The following Firestore collections are configured:

- `users` - User profiles, preferences, rewards
- `venues` - Dubai venue data with tables and events
- `guestListRequests` - Guest list applications
- `bookings` - Table reservations
- `tickets` - Event ticket purchases
- `kycSubmissions` - Know Your Customer submissions
- `safetyEvents` - Security and compliance events

## Automated Setup Steps

### 1. Prerequisites

```bash
# Install Firebase CLI if not already installed
npm install -g firebase-tools

# Install Node.js dependencies
npm install firebase-admin uuid
```

### 2. Run Automated Setup

```bash
# Make script executable and run
chmod +x setup_firebase.sh
./setup_firebase.sh
```

This will:
- Authenticate Firebase CLI
- Set project to `glist-6e64f`
- Enable Firestore, Auth, and Storage services
- Deploy security rules and indexes

### 3. Manual Steps in Firebase Console

1. **Authentication Setup**
   - Go to [Firebase Console](https://console.firebase.google.com/project/glist-6e64f)
   - Enable Email/Password sign-in provider
   - Configure any additional auth methods as needed

2. **Download Service Account Key**
   - Go to Project Settings > Service Accounts
   - Generate new private key for Firebase Admin SDK
   - Save as `serviceAccountKey.json` in project root

### 4. Seed Database

```bash
# Run the seeding script (after adding service account key)
node seed_database.js
```

This populates Firestore with initial Dubai venue data matching your `VenueData.dubaiVenues`.

## Security Rules

### Firestore Rules Features:

- **Users**: Can read/write own data, admin has full access
- **Venues**: Public read access, venue managers can edit
- **Guest Lists/Bookings**: Users manage own requests, venues/admin can view
- **KYC**: Private user documents, admin review access
- **Tickets**: Purchase management with venue oversight
- **Safety Events**: Server-side logging, admin read-only

### Storage Rules Features:

- **Profile Images**: User-controlled with public read
- **KYC Documents**: Private user access with admin override
- **Venue/Event Images**: Public read, venue manager upload

## Database Schema Updates

The app includes automatic schema migration via `DatabaseUpdateView.swift` that adds:

- Venue coordinates and table data
- User social features (following/followers)
- Ticket type definitions for events
- Enhanced user profile fields

## Verification

After setup:

1. Check Firebase Console to verify services are enabled
2. Run `firebase deploy --only firestore:rules` to confirm rules are active
3. Test the iOS app's DatabaseSeedView to verify initial data loads
4. Use DatabaseUpdateView to run schema migrations

## Troubleshooting

- **FIRESTORE_RULES_VALIDATION_ERROR**: Check rules syntax in `firestore.rules`
- **PERMISSION_DENIED**: Review security rules for your user role
- **INDEX_NOT_FOUND**: Deploy indexes with `firebase deploy --only firestore:indexes`

For issues, check the Firebase Console logs and ensure all prerequisites are met.
