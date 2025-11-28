# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Non-Obvious Documentation Rules

### Architecture Patterns
- **Singleton Managers**: All managers (FirestoreManager, LoyaltyManager, AuthManager, etc.) use `static let shared = ClassName()` - centralized data operations.
- **Centralized DI**: All managers instantiated in `GListApp.swift` and injected as environment objects - modify dependency creation here.
- **RTL Support**: `localeManager.usesRTL` controls right-to-left layouts for Dubai compliance.

### Data Patterns
- **Fallback Strategy**: `VenueManager` falls back to `VenueData.dubaiVenues` when Firestore unavailable - ensures offline functionality.
- **Atomic Operations**: Loyalty points use Firestore transactions for thread-safe updates - prevents race conditions.

### Business Logic
- **Automatic Sanctions**: `incrementNoShowCount()` applies soft bans (2 no-shows, 7 days) and hard bans (4+ no-shows) automatically.
- **Safety Audit**: All KYC changes, bans, no-shows trigger `safetyEvents` collection logging.
- **Deposit Calculation**: Table bookings require automatic 20% deposit calculation.

### UI Patterns
- **View Size Limits**: Extract subviews when view bodies exceed ~150 lines to prevent massive structs.
- **Theme System**: Use `Theme.Fonts.title/.headline` and `Color.theme.primary` for consistent styling.
- **Custom Modifiers**: Apply `.cardStyle()` and `.buttonStyle()` extensions for unified UI components.

### Testing Priorities
- **Critical Tests**: Focus on QR generation (`QRCodeGenerator`), booking flows, and validation logic.
- **Device Requirements**: Camera features require physical iOS devices - simulator insufficient.
- **Simulator Spec**: Use iPhone 16 simulator for testing compatibility.