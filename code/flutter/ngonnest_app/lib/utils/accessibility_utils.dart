import 'package:flutter/material.dart';
import 'dart:math' as dart_math;

/// Utility class for accessibility-related functions
class AccessibilityUtils {
  /// Calculates the contrast ratio between two colors
  /// Returns a value between 1 and 21, where 21 is the highest contrast
  static double calculateContrastRatio(Color color1, Color color2) {
    final luminance1 = _calculateLuminance(color1);
    final luminance2 = _calculateLuminance(color2);
    
    final lighter = luminance1 > luminance2 ? luminance1 : luminance2;
    final darker = luminance1 > luminance2 ? luminance2 : luminance1;
    
    return (lighter + 0.05) / (darker + 0.05);
  }
  
  /// Calculates the relative luminance of a color
  /// Based on WCAG 2.1 guidelines
  static double _calculateLuminance(Color color) {
    final r = _linearizeColorComponent(color.red / 255.0);
    final g = _linearizeColorComponent(color.green / 255.0);
    final b = _linearizeColorComponent(color.blue / 255.0);
    
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }
  
  /// Linearizes a color component for luminance calculation
  static double _linearizeColorComponent(double component) {
    if (component <= 0.03928) {
      return component / 12.92;
    } else {
      return ((component + 0.055) / 1.055).pow(2.4);
    }
  }
  
  /// Checks if a color combination meets WCAG AA standards (4.5:1 ratio)
  static bool meetsWCAGAA(Color foreground, Color background) {
    return calculateContrastRatio(foreground, background) >= 4.5;
  }
  
  /// Checks if a color combination meets WCAG AAA standards (7:1 ratio)
  static bool meetsWCAGAAA(Color foreground, Color background) {
    return calculateContrastRatio(foreground, background) >= 7.0;
  }
  
  /// Validates theme colors for accessibility compliance
  static Map<String, dynamic> validateThemeAccessibility(ThemeData theme) {
    final results = <String, dynamic>{};
    final colorScheme = theme.colorScheme;
    
    // Check primary text on background
    final primaryTextRatio = calculateContrastRatio(
      colorScheme.onBackground, 
      colorScheme.background
    );
    results['primaryText'] = {
      'ratio': primaryTextRatio,
      'meetsAA': primaryTextRatio >= 4.5,
      'meetsAAA': primaryTextRatio >= 7.0,
    };
    
    // Check primary text on surface
    final surfaceTextRatio = calculateContrastRatio(
      colorScheme.onSurface, 
      colorScheme.surface
    );
    results['surfaceText'] = {
      'ratio': surfaceTextRatio,
      'meetsAA': surfaceTextRatio >= 4.5,
      'meetsAAA': surfaceTextRatio >= 7.0,
    };
    
    // Check primary button text
    final primaryButtonRatio = calculateContrastRatio(
      colorScheme.onPrimary, 
      colorScheme.primary
    );
    results['primaryButton'] = {
      'ratio': primaryButtonRatio,
      'meetsAA': primaryButtonRatio >= 4.5,
      'meetsAAA': primaryButtonRatio >= 7.0,
    };
    
    // Check secondary button text
    final secondaryButtonRatio = calculateContrastRatio(
      colorScheme.onSecondary, 
      colorScheme.secondary
    );
    results['secondaryButton'] = {
      'ratio': secondaryButtonRatio,
      'meetsAA': secondaryButtonRatio >= 4.5,
      'meetsAAA': secondaryButtonRatio >= 7.0,
    };
    
    return results;
  }
}

// Extension to add pow method to double
extension DoubleExtension on double {
  double pow(double exponent) {
    return dart_math.pow(this, exponent).toDouble();
  }
}