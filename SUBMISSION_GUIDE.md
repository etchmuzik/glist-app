# LSTD App Store Submission Guide

## 1. Final Checks Completed

- [x] **App Name:** Updated to "LSTD"
- [x] **Bundle Display Name:** Set to "LSTD"
- [x] **Version:** 1.0, Build 2
- [x] **Debug Code:** Cleaned up (Demo Production Mode active for payments)
- [x] **Release Build:** Verified successfully

## 2. How to Archive and Submit

Since you are signed in to Xcode, follow these steps to upload your build to App Store Connect:

1. **Open Xcode** and make sure the **Glist** project is open.
2. Select **Any iOS Device (arm64)** from the destination dropdown (top bar, where you select simulators).
3. Go to the **Product** menu -> **Archive**.
4. Wait for the build to complete. The **Organizer** window will open automatically.
5. Select the latest archive (Version 1.0, Build 2).
6. Click **Distribute App**.
7. Select **App Store Connect** -> **Upload**.
8. Follow the prompts (keep default settings for signing and distribution).
9. Click **Upload**.

## 3. App Store Connect Setup

Once the upload is complete:

1. Go to [App Store Connect](https://appstoreconnect.apple.com).
2. Create a new App (if you haven't already) or select "LSTD".
3. **Screenshots:** Upload the screenshots we generated.
    - You have 7 high-quality screenshots ready.
    - If you need more, you can take them manually in the Simulator (`Cmd + S`) or wait for the API quota to reset.
4. **Build:** Select the build you just uploaded (it may take a few minutes to process).
5. **Submit for Review**.

## 4. Note on "Demo Production" Mode

Remember that **Payments are currently in Demo Mode**.

- Real credit cards will **NOT** be charged.
- All payments will succeed with a mock transaction ID.
- This is perfect for App Store Reviewers to test the app without needing a real credit card.
- **IMPORTANT:** Before you go live to real users, you must switch this back to real Stripe keys!

## 5. Screenshots

The following screenshots are available in your artifacts:

1. `screenshot_home_venue_list.png`
2. `screenshot_venue_detail.png`
3. `screenshot_digital_ticket.png`
4. `screenshot_map_view.png`
5. `screenshot_profile_vip.png`
6. `screenshot_social_activity.png`
7. `screenshot_table_reservation.png`

Good luck with the submission!
