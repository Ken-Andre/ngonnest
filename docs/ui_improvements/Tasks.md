# Implementation Plan

- [x] 1. Make the dashboard interactive
  - ✅ Make `StatsCard` widgets tappable and navigate to detailed lists
  - ✅ Add a `SyncBanner` showing last sync time and turning red after 30 s
  - _Requirements: 1_

- [x] 2. Add search and filters to the inventory
  - ✅ Integrate a search bar with 150 ms debounce and real-time filtering
  - ✅ Create a filter panel (room, expiry date) whose state persists on navigation
  - ✅ Allow quick quantity updates directly from the list with immediate save
  - ✅ Add room/location field to Objet model for better organization
  - ✅ Implement InventorySearchBar widget with clear button and validation
  - ✅ Implement InventoryFilterPanel with expandable interface and active filter counter
  - ✅ Implement QuickQuantityUpdate widget with in-place editing and error handling
  - _Requirements: 2_

- [ ] 3. Implement budget alerts
  - [ ] Enable creation and editing of budget categories
  - [ ] Trigger visual alerts and local notifications when spending >100 % of limit
  - [ ] Show monthly expense history loading in under 2 s
  - _Requirements: 3_

- [ ] 4. Persist settings and support multiple languages
  - [ ] Save preferences via `SharedPreferences`
  - [ ] Apply the selected language dynamically with English fallback
  - [ ] Handle notification enable/disable with permission prompts and error messaging
  - _Requirements: 4_

- [ ] 5. Improve accessibility and feedback
  - [ ] Verify contrast ratios for light/dark themes (≥4.5:1)
  - [ ] Display clear error messages with retry when sync fails or times out
  - [ ] Confirm successful actions via SnackBars or toasts visible ≥2 s
  - _Requirements: 5_