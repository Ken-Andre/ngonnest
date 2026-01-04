# Project Brief - NgoNest

## Core Mission
NgoNest is a comprehensive household management application designed specifically for the Cameroonian market, focusing on inventory management, budget tracking, and smart consumption optimization.

## Target User
Primary target: Cameroonian mothers aged 45-60 who are comfortable with WhatsApp and Mobile Money but new to digital inventory management.

## Core Problem Solved
Cameroonian households struggle with:
- Food waste due to poor inventory tracking
- Budget overruns from impulse purchases
- Inability to predict household needs
- Lack of smart consumption planning
- No offline-first solutions for areas with poor connectivity

## Success Criteria
The application must pass the "52-year-old Cameroonian mother test": any feature must be understandable and usable in under 30 seconds without prior digital experience.

## Technical Constraints
- **Offline First**: 100% functionality without internet
- **Performance**: <25MB app size, <2s load time, <1% battery/day
- **Compatibility**: Android 8.0+ (75% of Cameroonian market)
- **Memory**: Works on devices with 2GB RAM minimum

## Architecture Requirements
- MVVM + Repository Pattern
- SQLite with AES-256 encryption
- Comprehensive error logging
- Intuitive navigation (max 3 clicks to critical actions)

## Non-Negotiable Features
1. **Offline inventory management** with smart categorization
2. **Budget tracking** with visual spending analysis
3. **Consumption prediction** based on household patterns
4. **Multi-language support** (French, English, other languages later)
5. **Export/Import** functionality for data portability
6. **Calendar integration** for consumption planning

## Success Metrics
- User can complete full inventory cycle in <2 minutes
- Budget accuracy within 5% of actual spending
- 90% of features usable without internet
- App rating >4.5 stars on Play Store
- <1% daily active user churn rate
