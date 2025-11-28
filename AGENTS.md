# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Non-Obvious Project Patterns

### Architecture Patterns
- **Singleton Manager Pattern**: All data managers (FirestoreManager, LoyaltyManager, AuthManager, etc.) use `static let shared = ClassName()` - centralize data operations through singletons rather than dependency injection.
- **Centralized DI in App Delegate**: All managers instantiated in `GListApp.swift` and injected as environment objects - modify dependency creation here, not in individual views.
- **RTL Localization**: Uses `localeManager.usesRTL` for right-to-left layouts - Dubai-specific requirement affecting all UI components.

### Data Resilience Patterns
- **Fallback to Hardcoded Data**: `VenueManager` falls back to `VenueData.dubaiVenues` when Firestore fails - ensures app remains functional offline.
- **Atomic Point Operations**: Loyalty points use Firestore transactions (`db.runTransaction`) for thread-safe updates - prevents race conditions in reward systems.

### Business Logic Patterns
- **Automatic No-Show Bans**: `incrementNoShowCount()` applies soft bans (2 no-shows, 7 days) and hard bans (4+ no-shows) automatically - compliance requirement for venue operations.
- **Safety Event Logging**: All KYC status changes, bans, and no-shows trigger safety events in `safetyEvents` collection - mandatory audit trail.
- **Deposit Calculation**: Table bookings require 20% deposit automatically calculated and processed before confirmation.

### UI/UX Patterns
- **View Size Limits**: Extract subviews when view bodies exceed ~150 lines - prevents massive, unmaintainable view structs.
- **Custom Theme System**: Use `Theme.Fonts.title/.headline` and `Color.theme.primary` consistently - centralized theming prevents style drift.
- **Card/Button Modifiers**: Apply `.cardStyle()` and `.buttonStyle()` extensions for consistent UI components.

### Testing Priorities
- **QR Generation Validation**: Critical tests for `QRCodeGenerator` - failures break guest list and ticket scanning.
- **Manager Logic Tests**: Focus on booking flows, loyalty calculations, and state machines in unit tests.
- **Camera-Dependent Features**: UI tests for scan flows require physical devices - simulator testing insufficient.

### Build Requirements
- **Physical Device for Camera**: QR scanning and guest list features require camera permissions on actual iOS devices.
- **Specific Simulator**: Use iPhone 16 simulator for testing (`'platform=iOS Simulator,name=iPhone 16'`) - other simulators may have compatibility issues.
