import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ngonnest_app/utils/accessibility_utils.dart';
import 'package:ngonnest_app/theme/app_theme.dart';

void main() {
  group('AccessibilityUtils', () {
    test('should calculate correct contrast ratio for black and white', () {
      const black = Color(0xFF000000);
      const white = Color(0xFFFFFFFF);

      final ratio = AccessibilityUtils.calculateContrastRatio(black, white);

      // Black and white should have the maximum contrast ratio of 21:1
      expect(ratio, closeTo(21.0, 0.1));
    });

    test('should calculate correct contrast ratio for same colors', () {
      const color = Color(0xFF808080);

      final ratio = AccessibilityUtils.calculateContrastRatio(color, color);

      // Same colors should have a contrast ratio of 1:1
      expect(ratio, closeTo(1.0, 0.1));
    });

    test('should meet WCAG AA standards for high contrast colors', () {
      const black = Color(0xFF000000);
      const white = Color(0xFFFFFFFF);

      expect(AccessibilityUtils.meetsWCAGAA(black, white), isTrue);
      expect(AccessibilityUtils.meetsWCAGAAA(black, white), isTrue);
    });

    test('should not meet WCAG AA standards for low contrast colors', () {
      const lightGray = Color(0xFFCCCCCC);
      const white = Color(0xFFFFFFFF);

      expect(AccessibilityUtils.meetsWCAGAA(lightGray, white), isFalse);
    });

    group('Theme Accessibility Validation', () {
      test('should validate light theme accessibility', () {
        final lightTheme = AppTheme.lightTheme;
        final results = AccessibilityUtils.validateThemeAccessibility(
          lightTheme,
        );

        // Check that all text combinations meet WCAG AA standards
        expect(
          results['primaryText']['meetsAA'],
          isTrue,
          reason:
              'Primary text on background should meet WCAG AA (ratio: ${results['primaryText']['ratio']})',
        );

        expect(
          results['surfaceText']['meetsAA'],
          isTrue,
          reason:
              'Surface text should meet WCAG AA (ratio: ${results['surfaceText']['ratio']})',
        );

        expect(
          results['primaryButton']['meetsAA'],
          isTrue,
          reason:
              'Primary button text should meet WCAG AA (ratio: ${results['primaryButton']['ratio']})',
        );

        expect(
          results['secondaryButton']['meetsAA'],
          isTrue,
          reason:
              'Secondary button text should meet WCAG AA (ratio: ${results['secondaryButton']['ratio']})',
        );
      });

      test('should validate dark theme accessibility', () {
        final darkTheme = AppTheme.darkTheme;
        final results = AccessibilityUtils.validateThemeAccessibility(
          darkTheme,
        );

        // Check that all text combinations meet WCAG AA standards
        expect(
          results['primaryText']['meetsAA'],
          isTrue,
          reason:
              'Primary text on background should meet WCAG AA (ratio: ${results['primaryText']['ratio']})',
        );

        expect(
          results['surfaceText']['meetsAA'],
          isTrue,
          reason:
              'Surface text should meet WCAG AA (ratio: ${results['surfaceText']['ratio']})',
        );

        expect(
          results['primaryButton']['meetsAA'],
          isTrue,
          reason:
              'Primary button text should meet WCAG AA (ratio: ${results['primaryButton']['ratio']})',
        );

        expect(
          results['secondaryButton']['meetsAA'],
          isTrue,
          reason:
              'Secondary button text should meet WCAG AA (ratio: ${results['secondaryButton']['ratio']})',
        );
      });

      test('should print contrast ratios for manual verification', () {
        print('\n=== Light Theme Contrast Ratios ===');
        final lightResults = AccessibilityUtils.validateThemeAccessibility(
          AppTheme.lightTheme,
        );
        lightResults.forEach((key, value) {
          print(
            '$key: ${value['ratio'].toStringAsFixed(2)}:1 (AA: ${value['meetsAA']}, AAA: ${value['meetsAAA']})',
          );
        });

        print('\n=== Dark Theme Contrast Ratios ===');
        final darkResults = AccessibilityUtils.validateThemeAccessibility(
          AppTheme.darkTheme,
        );
        darkResults.forEach((key, value) {
          print(
            '$key: ${value['ratio'].toStringAsFixed(2)}:1 (AA: ${value['meetsAA']}, AAA: ${value['meetsAAA']})',
          );
        });
      });
    });

    group('Specific Color Combinations', () {
      test('should validate NgonNest primary colors meet accessibility standards', () {
        // Test primary green on white
        final greenOnWhite = AccessibilityUtils.calculateContrastRatio(
          AppTheme.primaryGreen,
          AppTheme.neutralWhite,
        );
        expect(
          greenOnWhite,
          greaterThanOrEqualTo(4.5),
          reason:
              'Primary green on white should meet WCAG AA (ratio: ${greenOnWhite.toStringAsFixed(2)})',
        );

        // Test white on primary green
        final whiteOnGreen = AccessibilityUtils.calculateContrastRatio(
          AppTheme.neutralWhite,
          AppTheme.primaryGreen,
        );
        expect(
          whiteOnGreen,
          greaterThanOrEqualTo(4.5),
          reason:
              'White on primary green should meet WCAG AA (ratio: ${whiteOnGreen.toStringAsFixed(2)})',
        );

        // Test neutral black on light grey
        final blackOnLightGrey = AccessibilityUtils.calculateContrastRatio(
          AppTheme.neutralBlack,
          AppTheme.neutralLightGrey,
        );
        expect(
          blackOnLightGrey,
          greaterThanOrEqualTo(4.5),
          reason:
              'Black on light grey should meet WCAG AA (ratio: ${blackOnLightGrey.toStringAsFixed(2)})',
        );

        // Test neutral grey on white (for secondary text)
        final greyOnWhite = AccessibilityUtils.calculateContrastRatio(
          AppTheme.neutralGrey,
          AppTheme.neutralWhite,
        );
        expect(
          greyOnWhite,
          greaterThanOrEqualTo(4.5),
          reason:
              'Neutral grey on white should meet WCAG AA (ratio: ${greyOnWhite.toStringAsFixed(2)})',
        );
      });
    });
  });
}
