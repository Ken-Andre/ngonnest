# NgonNest - Product Context

## Overview
Mobile household inventory management app for Cameroon market with offline-first architecture.

## Core Features
- **Inventory tracking**: Products, quantities, expiration dates, room locations
- **Budget management**: Monthly categories, spending alerts, expense tracking
- **Offline-first**: Full functionality without internet via SQLite
- **Smart notifications**: Low stock, expiration, budget alerts
- **Cloud sync**: Optional Supabase sync when online

## Target Users
- Cameroon households managing domestic inventory
- Users with intermittent internet connectivity
- French-speaking primary audience (FR/EN/ES supported)
- Mobile-first (Android focus)

## Key Principles
- **Offline-first**: App must work without network
- **Local wins**: In sync conflicts, local data takes precedence
- **Privacy-focused**: No personal data collection, encrypted local storage
- **Cameroon-optimized**: FCFA currency, local product prices, French UI

## User Experience Test
Every feature must pass: "Would a 52-year-old Cameroonian mother familiar with WhatsApp and Mobile Money understand and use this in under 30 seconds?"

## License
Proprietary - requires Product Owner approval before use or sharing.
