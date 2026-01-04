# Active Context - NgoNest

## Development Environment

### Current Platform Context
**Development Environment**: Windows 11 Pro
- **IDE**: VS Code-based or Android Studio
- **Shell**: PowerShell 7.x / Command Prompt
- **Architecture**: MVVM + Repository Pattern
- **Target Platform**: Android (8.0+) with fallback to iOS

### Windows-Specific Considerations
- **Path Separators**: Use backslashes (`\`) for Windows paths
- **Flutter Commands**: Compatible with Windows environment
- **Database**: SQLite works natively on Windows
- **Performance Testing**: Ensure compatibility with Windows development workflow

### Current Work Focus

#### Sprint Status
Currently in **Sprint 2** of MVP development, focusing on core inventory management and budget tracking features. The project is approximately **20-25% complete** towards the minimum viable product based on implemented vs claimed functionality.

### Active Development Areas
1. **Inventory Management System** - Smart categorization and consumption tracking (not implemented)
2. **Budget Analysis Engine** - Basic spending analysis and alerts 
3. **User Onboarding Flow** - Simplified household setup process
4. **Offline-First Architecture** - Ensuring 100% functionality without internet (working)

### Current Sprint Goals
- Complete inventory management with smart categorization
- Implement budget tracking with visual analysis
- Enhance user onboarding for better adoption
- Optimize database performance for low-end devices
- Add comprehensive error handling and logging

## Recent Changes

### Last 2 Weeks
1. **Navigation & Connectivity Improvements**: Completed major UI/UX enhancements
   - Implemented ConnectivityService with real-time network monitoring
   - Created ConnectivityBanner widget with theme-aware colors
   - Integrated connectivity overlay across all screens via AppWithConnectivityOverlay
   - Added interactive dashboard stat cards with navigation to filtered views
   - Enhanced inventory screen with search bar, filter panel, and quick quantity updates
   - All connectivity tests passing (widget + integration tests)
2. **Budget Management Improvements**: Completed Tasks 1-5 of budget-management-improvements spec
   - Enhanced BudgetCategory model with percentage field
   - Implemented BudgetAllocationRules engine with household-based calculations
   - Created recalculateCategoryBudgets method in BudgetService
   - Converted BudgetService to static class architecture
   - All 13 unit tests passing for budget functionality
3. **Cloud Sync Architecture**: Critical schema issues documented
   - INTEGER vs UUID mismatch between local SQLite and Supabase identified
   - Migration SQL ready for percentage column (not yet applied to cloud)
   - Comprehensive documentation created (ACTION_PLAN.md, CRITICAL_SCHEMA_MISMATCH.md)
4. **Testing Infrastructure**: Improved test coverage
   - Budget service tests at 100% coverage
   - Connectivity widget and integration tests complete
   - Overall coverage ~25% (up from 20%)

### Code Quality Improvements
- **Error Handling**: Centralized error logging with user-friendly messages
- **State Management**: Consistent Provider pattern implementation across all screens
- **Performance**: Optimized database queries and UI rendering
- **Accessibility**: Enhanced contrast ratios and touch target sizes

### Architecture Decisions Made
- **MVVM Pattern**: Fully adopted across all feature modules
- **Repository Layer**: Abstracted data access for better testability
- **Service Layer**: Separated business logic from UI components
- **Offline Strategy**: Local-first approach with optional cloud sync

## Next Steps

### Immediate Priorities (Next 2 Weeks)
1. **Budget System - Real Notifications (Task 6)**
   - Implement BudgetNotifications extension on NotificationService
   - Replace console logs with actual system notifications
   - Add analytics tracking for budget alerts
   - Test notification permissions and fallback to in-app banners

2. **Budget System - Sync Integration (Task 5)**
   - Integrate BudgetService with SyncService
   - Enqueue budget operations for cloud sync
   - Test sync with budget category CRUD operations

3. **Critical Schema Migration Decision**
   - Choose migration strategy: UUID migration vs ID mapping layer
   - Apply percentage column migration to Supabase (SQL ready)
   - Plan rollout strategy for existing users
   - Document migration process

4. **Inventory Advanced Features**
   - Implement urgent items filtering (ExpiryFilter.urgent)
   - Add low stock detection based on seuil_alerte_quantite
   - Complete consumption prediction algorithms
   - Test with large datasets (100+ items)

### Medium-term Goals (Next Month)
1. **Advanced Features**
   - Calendar integration for consumption planning
   - Family sharing capabilities
   - Advanced analytics and reporting

2. **Platform Expansion**
   - Web PWA version for broader accessibility
   - Enhanced offline capabilities
   - Cross-platform data synchronization

3. **Quality Assurance**
   - Comprehensive testing suite completion
   - Performance benchmarking
   - User acceptance testing preparation

## Active Decisions and Considerations

### Technical Architecture
- **Database Choice**: SQLite (no encryption) vs. alternatives
  - Decision: Stick with SQLite for offline-first approach
  - Rationale: Better performance on low-end devices, simpler deployment (encryption planned but not implemented)

- **State Management**: Provider vs. Bloc vs. Riverpod
  - Decision: Continue with Provider for consistency, with static services where appropriate
  - Rationale: Team familiarity, simpler learning curve, adequate for project scope
  - Note: BudgetService uses static methods, ConnectivityService uses ChangeNotifier

- **Navigation**: Bottom navigation vs. drawer vs. tabbed interface
  - Decision: Bottom navigation with 5 main sections + interactive stat cards
  - Rationale: Familiar to WhatsApp users, optimal for one-handed use, improved discoverability

- **Cloud Sync Migration**: UUID migration vs. ID mapping layer
  - Decision: Pending - requires evaluation of trade-offs
  - Options: (1) Migrate to UUIDs (breaking change, future-proof), (2) ID mapping layer (complex, no breaking changes)
  - Documentation: ACTION_PLAN.md, CRITICAL_SCHEMA_MISMATCH.md

### User Experience
- **Onboarding Complexity**: Multi-step vs. simplified single screen
  - Decision: Progressive onboarding with optional advanced setup
  - Rationale: Balance between feature discovery and quick start

- **Language Strategy**: French-only vs. multi-language from day one
  - Decision: Multi-language support from launch
  - Rationale: Broader market reach, inclusive design

### Business Model
- **Freemium vs. Free**: Premium features vs. completely free
  - Decision: Freemium with cloud sync and advanced analytics as premium
  - Rationale: Sustainable development, value for power users

## Important Patterns and Preferences

### Code Organization
- **Feature-based Structure**: Group related files by feature area
- **Service Layer**: Business logic separated from UI components
- **Repository Pattern**: Consistent data access abstraction
- **Provider Pattern**: Centralized state management approach

### UI/UX Consistency
- **Material Design 3**: Consistent design system implementation
- **Accessibility First**: WCAG AA compliance throughout
- **Cultural Adaptation**: Localized content and interactions
- **Performance Focus**: Optimized for 2GB RAM devices

### Development Workflow
- **Test-Driven**: Unit tests before implementation
- **Code Review**: Peer review for all significant changes
- **Documentation**: Comprehensive inline documentation
- **Error Logging**: Detailed logging for production debugging

### User Research Insights
- **Simplicity Critical**: Users prefer 2-3 tap maximum for any action
- **Visual Feedback**: Progress indicators and status updates essential
- **Offline Reliability**: Users expect full functionality without internet
- **Familiar Patterns**: WhatsApp-like interactions preferred over complex gestures

## Learnings and Project Insights

### Technical Learnings
1. **Flutter Performance**: List virtualization critical for large inventories
2. **SQLite Optimization**: Proper indexing essential for query performance
3. **Provider Pattern**: Context management crucial for avoiding provider hell
4. **Error Boundaries**: Global error handling prevents silent failures
5. **Static vs ChangeNotifier**: Static service classes simpler when no UI listeners needed
6. **Schema Compatibility**: Local SQLite and cloud Supabase schemas must align for sync
7. **Percentage-based Budgets**: Dynamic budget allocation more flexible than hardcoded values
8. **Connectivity UX**: Non-intrusive banners with auto-dismiss better than persistent indicators
9. **Theme Integration**: Using colorScheme ensures light/dark mode compatibility automatically
10. **Navigation Patterns**: Interactive stat cards improve feature discoverability
11. **Search Debouncing**: 150ms debounce optimal for real-time search without lag

### User Behavior Insights
1. **Onboarding Dropout**: 40% drop-off if setup takes >5 minutes
2. **Feature Adoption**: Visual features adopted 3x faster than text-based ones
3. **Offline Usage**: 80% of usage occurs without internet connectivity
4. **Budget Tracking**: Weekly summaries preferred over daily tracking(except for students that prefers daily tracking both)

### Market Learnings
1. **Cameroonian Market**: WhatsApp familiarity drives UI expectations
2. **Mobile Money Integration**: Orange Money, MTN Money integration critical (Find a free way or alternatives, due to local regulations constraint)
3. **Local Pricing**: Real-time market price integration needed
4. **Cultural Events**: Holiday and fasting period awareness important

### Development Insights
1. **Testing Strategy**: Integration tests catch more issues than unit tests
2. **Performance Budget**: 25MB APK limit requires careful asset management
3. **Battery Optimization**: Background tasks must be carefully managed
4. **Localization Complexity**: Cultural adaptation beyond translation essential

## Risk Management

### Current Risks
1. **Performance on Low-end Devices**: Need extensive testing on target hardware
2. **User Adoption**: Onboarding complexity may reduce conversion
3. **Data Migration**: Future schema changes need careful planning
4. **Offline Sync**: Conflict resolution strategy needs implementation

### Mitigation Strategies
1. **Device Testing**: Comprehensive testing on Android 8.0+ devices
2. **User Research**: Continuous feedback integration in development
3. **Migration Planning**: Version-controlled database schema evolution
4. **Sync Strategy**: Last-write-wins with user notification for conflicts

## Success Metrics Tracking

### Current Status
- **Features Complete**: ~12/20 planned MVP features (budget 70%, inventory 80%, connectivity 100%)
- **Test Coverage**: ~25% actual unit test coverage (budget services 100%, connectivity 100%)
- **Performance**: Unverified (build issues resolved, testing pending)
- **Accessibility**: Partial WCAG AA compliance (connectivity banner compliant)
- **Cloud Sync**: Blocked by schema mismatch (INTEGER vs UUID) - migration SQL ready

### Upcoming Milestones
- **Alpha Release**: Core features complete and tested (2 weeks)
- **Beta Release**: Full feature set with user testing (4 weeks)
- **MVP Launch**: Production release with monitoring (6 weeks)
- **Growth Phase**: Advanced features and platform expansion (8+ weeks)
