# Ethical Resale Prototype for Glist

## Goals
1. Provide a safe resale path for guests who can no longer attend without enabling price gouging.
2. Keep the resale experience tied to guest-list rules such as deposits, no-show bans and QR-based tracking.
3. Surface resale opportunities in the existing ticket management UI so users do not leave the app.

## Proposed Components
- **ResaleManager (singleton)**: mirrors patterns in `GuestListManager` and `LoyaltyManager`. Handles:
  - Publishing resale offers for bookings that meet criteria (payment completed, not checked in). 20% deposit remains with venue; resale covers remaining balance. 
  - Validating buyers: require KYC status `approved` and zero recent bans. Reuse `KYCModels` and safety logging in `safetyEvents` collection.
  - Enforcing ethical pricing: built-in price cap (purchase price + service fee) and dynamic `DynamicPricingEngine` call to keep resale fair.
  - Managing QR transfer: assign new `qrCodeId` when ticket transfers to a resale buyer; reuse `QRCodeGenerator` to regenerate codes and `OfflineScanCache` for offline syncing.

- **Resale Offer Model**: new struct like `ResaleOffer { id, bookingId, sellerId, price, status, createdAt }` stored under `bookings/{bookingId}/resaleOffers`. Status transitions use `ReservationStateMachine`. Soft ban or deposit forfeiture if unethical behavior detected (duplicate transfers, repeated cancellations).

- **Checkout integration**: `CheckoutView` and `TicketManagementView` gain resale button. Tapping shows `ResaleOfferView` where seller sets price (capped) and buyer checks out via `PaymentManager`, with payout credit going to seller (handled by `PayoutManagementView` and `PaymentsManager`). Physical deposit ensures venue credit, just like `Deposit.swift` logic.

- **Analytics & Safety**: `AnalyticsManager` tracks resale volume; `ReportingManager` logs each transfer + price cap checks. Safety events created for suspicious price increases or failed KYC verifications.

## Flow Sketch
1. Seller opens `TicketManagementView`, taps `Offer Resale`. `ResaleManager.shared.createOffer()` validates booking state and deposits link (`Deposit.current`).
2. Offer listed on `ForYouView`/`RecommendationEngine` for matched buyers (uses existing model). Buyers see `ResaleOfferView`, confirm identity, and pay through `CheckoutView` with `PaymentManager` and `ApplePayIntegration` if available.
3. After payment, `ResaleManager` transfers ownership: updates Firestore `booking.owner`, regenerates QR (`QRCodeGenerator`), logs safety event, updates `OfflineScanCache`, and notifies venue admins via `NotificationManager`.
4. `FirestoreManager.publishResaleOffer(ticket:offer:)` runs a transaction that validates the current seller, prohibits duplicate listings, writes `resaleOffers/{offerId}`, updates ticket metadata, and logs a `SafetyEventType.resaleOfferCreated`.

## UI Wireframe
- `ResaleOfferView` (new SwiftUI view) reuses `Theme.Fonts` + `.cardStyle()` so it stays consistent with existing cards. It keeps the body short, surfaces the price input, cap guidance, eligibility text, and a single “Publish Resale Offer” button. The view exposes an `onPublish` closure so it can be wired to `ResaleManager` actions or checkout flows without altering the view itself.

## Next Steps
1. Wireframe `ResaleOfferView` using existing theme modifiers (`Theme.Fonts`, `.cardStyle()`). Keep view bodies short per AGENTS guidance.
2. Extend Firestore rules (`firestore.rules`) to cover `resaleOffers` and ensure transactions update `bookings` atomically (`db.runTransaction`).
3. Add unit tests covering price cap logic and `ResaleManager` operations (focus per AGENTS testing priorities). QR/resale must still be validated via physical device scans.
