# Requirements Document

## Introduction

This document outlines functional requirements identified during a review of the NgonNest application. The goal is to improve the user experience by strengthening navigation, search, and preference management.

## Requirements

### Requirement 1: Interactive dashboard
**User Story:** As a user, I want to tap dashboard statistic cards to quickly access the related detailed lists.

**Acceptance Criteria:**
1. When the user taps the “Total items” card, the app shall open the full inventory list.
2. When the user taps the “Urgent items” card, the app shall show the filtered list of urgent items.
3. When the sync status changes, a banner shall update within 1 second and display the time since last sync. The banner turns red if no sync occurred for 30 seconds.

### Requirement 2: Inventory search and filters
**User Story:** As a user, I want to search and filter my items to find what I need quickly.

**Acceptance Criteria:**
1. When the user types in the search bar, the list shall refresh with matching items within 150 ms after the last keystroke.
2. When the user applies a room or expiry-date filter, only matching items shall be displayed and the filter state shall persist when navigating back.
3. When the user updates an item quantity from the list, the change shall be saved immediately and reflected in under 500 ms. If no item matches the query, an empty-state message shall be shown.

### Requirement 3: Custom budget alerts
**User Story:** As a user, I want to define budgets per category and be alerted when spending exceeds them.

**Acceptance Criteria:**
1. When monthly spending for a category exceeds 100 % of its limit, the app shall display a red alert banner and, if notification permission is granted, send a local notification within 5 seconds.
2. When the user creates a new category, it shall appear on the Budget screen with its configured limit.
3. When the user views history, expenses shall be grouped by month and the list shall load within 2 seconds.

### Requirement 4: Persistent and multilingual settings
**User Story:** As a user, I want my preferences (language, notifications) saved and applied throughout the app.

**Acceptance Criteria:**
1. When the user changes the language, the UI shall update immediately without restart and fall back to English for missing translations.
2. When notifications are disabled, no alerts shall be scheduled or delivered.
3. When the app is reopened, previous settings shall be restored from `SharedPreferences`.
4. When notification permission is denied, the app shall inform the user and offer a shortcut to system settings.

### Requirement 5: Accessibility and clear feedback
**User Story:** As a user, I want an accessible interface and explicit error messages to understand issues.

**Acceptance Criteria:**
1. When dark mode is active, all text shall maintain a contrast ratio of at least 4.5:1.
2. When a sync error occurs, a message shall appear with a retry action.
3. When an operation succeeds, a visual confirmation (SnackBar or toast) shall appear for at least 2 seconds.
4. When a network request exceeds 10 seconds, the app shall display a timeout message.

