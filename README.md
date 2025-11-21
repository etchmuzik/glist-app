# Glist - Dubai Nightlife Guide

## Features

- **Guest List Management**: Users can request guest list access to venues.
- **QR Code Check-in**:
  - Users receive a unique QR code for each confirmed booking.
  - Venue managers can scan QR codes to check guests in.
- **Admin Panel**: Manage venues, guest lists, and view analytics.

## QR Code System

The QR code system uses CoreImage for generation and AVFoundation for scanning.

- **Generation**: `QRCodeGenerator.swift` generates high-quality QR codes from booking IDs.
- **Scanning**: `QRScannerView.swift` provides a camera interface to scan codes.
- **Data Model**: `GuestListRequest` includes a `qrCodeId` which is used for verification.

## Setup

1. Install dependencies (Firebase).
2. Run on a physical device for camera features (Scanning).
