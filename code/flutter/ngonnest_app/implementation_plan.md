# Implementation Plan - Smart Product UX Improvements

## Overview
Implement intelligent UX improvements for the add product screen to reduce manual input by 80% and provide a delightful user experience. This includes auto-suggestions, hierarchical categories, smart quantity recommendations, and adaptive frequency selection.

## Types
### Product Template Model
New data structure for product templates with intelligent metadata:
```dart
class ProductTemplate {
  final int id;
  final String name;
  final String category;
  final String subcategory;
  final String unit;
  final Map<String, dynamic> quantityGuidelines; // {'family_4': 2.5, 'period': 30}
  final int defaultFrequency;
  final int popularity;
  final String icon;
  final String region; // For future regional adaptation
  final Map<String, int> commonQuantities; // {'4_persons': 6, '6_persons': 9}

  // Computed properties for smart recommendations
  double getRecommendedQuantity(int familySize) {
    // Intelligent calculation based on family size and usage patterns
  }
}
```

### Enhanced Category Hierarchy
```dart
class ProductCategory {
  final int id;
  final String name;
  final String icon;
  final String parentId; // For hierarchical structure
  final int priority; // For display ordering
  final List<String> commonProducts; // Associated product types
}
```

## Files

### New Files
#### `lib/services/product_intelligence_service.dart`
Purpose: Central service handling product intelligence, suggestions, and recommendations
```dart
class ProductIntelligenceService {
  // Methods:
  Future<List<ProductTemplate>> searchProducts(String query, String category);
  Future<List<String>> getCategoryHierarchy(String parentId);
  Future<double> calculateOptimalQuantity(ProductTemplate product, int familySize);
  Future<void> learnFromUserChoice(String productId, String category);
}
```

#### `lib/models/product_preset.dart`
Purpose: Data models for product presets and categories
```dart
// Product presets data structure with embedded hierarchical categories
const productPresets = [
  {
    'categories': [
      {'id': 'hygiene', 'name': 'Hygiène', 'subcategories': [
        {'id': 'savon', 'name': 'Savon', 'products': [...]},
        {'id': 'dentifrice', 'name': 'Dentifrice', 'products': [...]},
      ]},
      // ... more hierarchical categories
    ]
  }
];
```

#### `lib/widgets/smart_product_search.dart`
Purpose: Auto-suggesting search widget with intelligent filtering
```dart
class SmartProductSearch extends StatefulWidget {
  // Implementation with TypeAheadField and custom suggestions
}
```

#### `lib/widgets/hierarchical_category_selector.dart`
Purpose: Multi-level category selection with visual hierarchy
```dart
class HierarchicalCategorySelector extends StatefulWidget {
  // Breadcrumb navigation through category levels
}
```

### Modified Files
#### `lib/screens/add_product_screen.dart`
- **Changes**: Replace simple category grid with intelligent components
- **New widgets**: SmartProductSearch, HierarchicalCategorySelector, SmartQuantitySelector
- **Enhanced**: Add family size context for quantity recommendations
- **Integration**: Connect to ProductIntelligenceService for suggestions

#### `lib/services/database_service.dart`
- **Add method**: `upsertProductUsage(productId, category, familySize)` for learning
- **Add method**: `getPopularProductsByCategory(String category)` for trending suggestions

#### `lib/models/objet.dart`
- **Add method**: `getQuantityGuidelines()` to integrate with smart calculations
- **Add field**: `suggestedQuantity` for family-size-based recommendations

## Functions

### New Functions
#### Product Intelligence Service
- `searchProducts(filter: Map<String, dynamic>) → List<ProductTemplate>`
  - *file*: `lib/services/product_intelligence_service.dart`
  - *purpose*: Intelligent product search with multiple filters
- `getSmartQuantity(familySize: int, product: String, period: int) → double`
  - *file*: `lib/services/product_intelligence_service.dart`
  - *purpose*: Calculate optimal quantity based on family composition
- `updateProductPreferences(productId: String, userChoice: String) → void`
  - *file*: `lib/services/product_intelligence_service.dart`
  - *purpose*: Learn from user selections for better future suggestions

### Modified Functions
#### Add Product Screen
- `_buildProductSearchField() → Widget` modified to use SmartProductSearch
  - *file*: `lib/screens/add_product_screen.dart`
  - *purpose*: Replace basic TextFormField with intelligent search
- `_loadSuggestionsForCategory(category: String) → List<ProductTemplate>`
  - *file*: `lib/screens/add_product_screen.dart`
  - *purpose*: Load and cache category-specific suggestions

## Classes

### New Classes
#### SmartQuantitySelector
- **file**: `lib/widgets/smart_quantity_selector.dart`
- **methods**:
  - `buildSmartInputs()` - Render quantity with family size context
  - `calculateOptimalQuantity()` - Local calculation before service call
  - `validateWithGuidelines()` - Validate against learned patterns

#### ProductTemplateRenderer
- **file**: `lib/widgets/product_suggestion_card.dart`
- **methods**:
  - `renderWithContext()` - Show product with usage context
  - `highlightOptimalSize()` - Emphasize recommended quantities

### Modified Classes
#### AddProductScreenState
- **add properties**:
  - `familySize` from HouseholdService
  - `productSuggestions` cache
  - `categoryHierarchy` loaded data
- **add methods**:
  - `loadSmartSuggestions()` async method
  - `handleProductTemplateSelection()` for preset application
  - `refreshSuggestionsForContext()` when category changes

## Dependencies

### New Dependencies
- `flutter_typeahead: ^4.6.1` - For intelligent auto-suggestions
- `collection: ^1.17.0` - Enhanced collection utilities for category hierarchies

No major version changes required to existing dependencies.

## Testing

### Test File Requirements
#### `test/services/product_intelligence_service_test.dart`
- Unit tests for product search algorithms
- Mock data for suggestion ranking
- Integration tests with database layer

#### `test/widgets/smart_product_search_test.dart`
- Widget tests for search functionality
- Test suggestion filtering and ranking
- Performance tests for large product datasets

#### `test/screens/add_product_screen_enhanced_test.dart`
- Integration tests for complete flow
- Test smart quantity calculations
- Validate category hierarchy navigation

### Existing Tests Modification
#### Update `test/repository/inventory_repository_test.dart`
- Add tests for new product usage tracking methods
- Validate learning data persistence
- Test popular products retrieval

## Implementation Order

### Phase 1: Foundation (30 min)
1. Create ProductIntelligenceService with basic search
2. Add ProductTemplate and ProductCategory models
3. Create embedded product presets data structure

### Phase 2: Core UX Components (45 min)
1. Implement SmartProductSearch widget
2. Create HierarchicalCategorySelector
3. Build SmartQuantitySelector with family size context

### Phase 3: Screen Integration (45 min)
1. Modify AddProductScreen to use new components
2. Integrate ProductIntelligenceService
3. Add family size context from HouseholdService

### Phase 4: Learning & Optimization (30 min)
1. Implement user preference learning in database
2. Add popular products suggestion logic
3. Test complete user flow with mock data

### Phase 5: Testing & Polish (30 min)
1. Write unit tests for core logic
2. Integration testing with real database
3. UI polish and responsive design improvements

## Quality Standards
- **Performance**: Search suggestions under 100ms
- **Accuracy**: 95%+ matching for product searches
- **User Experience**: Reduce manual input by 80%
- **Maintenance**: Clear separation of concerns and extensible architecture
- **Accessibility**: Full keyboard navigation and screen reader support
