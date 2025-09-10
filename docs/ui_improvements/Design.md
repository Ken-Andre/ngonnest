# Design Document

## Overview
This document describes the design approach for the proposed UI/UX enhancements in NgonNest. The changes aim for a more interactive, customizable, and accessible interface.

## Architecture
- **Dashboard**: statistic cards become tappable widgets navigating to filtered views. A `SyncBanner` component displays last sync time and auto-hides when fresh (<30 s).
- **Inventory**: a `SearchBar` and `FilterPanel` operate on the local state of `InventoryViewModel` with a 150 ms debounce for queries.
- **Budget**: a `BudgetService` tracks spending per category, persists data in the local database, and triggers local notifications through `NotificationService` when limits are exceeded.
- **Settings**: use `SharedPreferences` for persistence and a `LocaleProvider` backed by the `intl` package for language switching with English fallback.

## Data Flow
1. Views query the local `Repository` (SQLite) to read or modify data.
2. Search filters operate in memory and persist changes via the `Repository`.
3. Budget alerts call `NotificationService` which requests permission on first use and schedules platform-specific notifications.

## Components and Interfaces
- `StatsCard` (dashboard) → navigates to detailed screens and exposes an `onTap` callback.
- `SyncBanner` → observes connectivity and sync time.
- `InventorySearchBar` and `FilterPanel` → expose callbacks to update the `InventoryViewModel`.
- `BudgetCategoryCard` → displays progress and handles alerts.
- `SettingsPage` → contains language selector and notification toggle tied to `SettingsService` and `LocaleProvider`.
- `NotificationService` → wraps `flutter_local_notifications` and handles permission prompts and error states.

## Data Models
- **Item**: adds `room` and `expiryDate` attributes for filtering.
- **BudgetCategory**: fields `limit`, `spent`, `month`.
- **Settings**: `language`, `notificationsEnabled`, and `lastSync` stored via `SharedPreferences`.

## Error Handling
- Sync errors display a banner with a retry action and log details for diagnostics.
- Critical actions (budget modifications) are confirmed through modal dialogs.
- If notification permission is denied, `NotificationService` emits a warning message.

## Testing Strategy
- Unit tests for `InventoryViewModel` (filtering, search debounce) and `BudgetService`.
- Widget tests verifying navigation from `StatsCard` and visibility of `SyncBanner`.
- Integration tests simulating language change, notification permissions, and persistence of settings.

## Implementation Notes
- Follow colors and typography defined in `AppTheme`.
- Ensure compatibility with light and dark modes and maintain ≥4.5:1 contrast.

