import 'package:flutter/material.dart';

class AppTheme {
  // Primary colors matching mobile prototype (CSS colors)
  static const Color primaryGreen = Color(0xFF027B3A);
  static const Color primaryOrange = Color(0xFFE58800);
  static const Color primaryRed = Color(0xFFC62828);
  static const Color primaryYellow = Color(0xFFFDD835);

  // Neutral colors for accessibility
  static const Color neutralBlack = Color(0xFF1A1A1A);
  static const Color neutralWhite = Color(0xFFFFFFFF);
  static const Color neutralGrey = Color(0xFF6B6B6B);
  static const Color neutralLightGrey = Color(0xFFF5F5F5);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      // Color scheme with high contrast for accessibility
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        brightness: Brightness.light,
        primary: primaryGreen,
        secondary: primaryRed,
        tertiary: primaryYellow,
        surface: neutralWhite,
        // background: neutralLightGrey,
        onPrimary: neutralWhite,
        onSecondary: neutralWhite,
        onSurface: neutralBlack,
        // onBackground: neutralBlack,
      ),

      // Typography with minimum 16px font size for accessibility
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: neutralBlack,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: neutralBlack,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: neutralBlack,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: neutralBlack,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: neutralBlack,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: neutralBlack,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: neutralBlack,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: neutralBlack,
        ),
        titleSmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: neutralBlack,
        ),
        bodyLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.normal,
          color: neutralBlack,
        ),
        bodyMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: neutralBlack,
        ),
        bodySmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: neutralGrey,
        ),
        labelLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: neutralBlack,
        ),
        labelMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: neutralBlack,
        ),
        labelSmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: neutralGrey,
        ),
      ),

      // App bar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: neutralWhite,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: neutralWhite,
        ),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: neutralWhite,
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGreen,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: neutralGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: neutralGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: const TextStyle(fontSize: 16, color: neutralGrey),
        hintStyle: const TextStyle(fontSize: 16, color: neutralGrey),
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: neutralWhite,
        elevation: 4,
        shadowColor: neutralBlack.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Icon theme
      iconTheme: const IconThemeData(color: primaryGreen, size: 24),

      // Floating action button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryGreen,
        foregroundColor: neutralWhite,
        elevation: 8,
      ),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: neutralWhite,
        selectedItemColor: primaryGreen,
        unselectedItemColor: neutralGrey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
      ),

      // Divider theme
      dividerTheme: const DividerThemeData(
        color: neutralGrey,
        thickness: 1,
        space: 1,
      ),

      // Progress indicator theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryGreen,
        linearTrackColor: neutralLightGrey,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color scheme for dark mode
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        brightness: Brightness.dark,
        primary: primaryGreen,
        secondary: primaryRed,
        tertiary: primaryYellow,
        surface: const Color(0xFF1E1E1E),
        background: const Color(0xFF121212),
        onPrimary: neutralWhite,
        onSecondary: neutralWhite,
        onSurface: neutralWhite,
        onBackground: neutralWhite,
      ),

      // Typography for dark mode
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: neutralWhite,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: neutralWhite,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: neutralWhite,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: neutralWhite,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: neutralWhite,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: neutralWhite,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: neutralWhite,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: neutralWhite,
        ),
        titleSmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: neutralWhite,
        ),
        bodyLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.normal,
          color: neutralWhite,
        ),
        bodyMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: neutralWhite,
        ),
        bodySmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: neutralLightGrey,
        ),
        labelLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: neutralWhite,
        ),
        labelMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: neutralWhite,
        ),
        labelSmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: neutralLightGrey,
        ),
      ),

      // App bar theme for dark mode
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: neutralWhite,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: neutralWhite,
        ),
      ),

      // Elevated button theme for dark mode
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: neutralWhite,
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),

      // Text button theme for dark mode
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGreen,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // Input decoration theme for dark mode
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: neutralGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: neutralGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: const TextStyle(fontSize: 16, color: neutralLightGrey),
        hintStyle: const TextStyle(fontSize: 16, color: neutralLightGrey),
      ),

      // Card theme for dark mode
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 4,
        shadowColor: neutralBlack.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Icon theme for dark mode
      iconTheme: const IconThemeData(
        color: neutralWhite, // Changed to neutralWhite for dark mode visibility
        size: 24,
      ),

      // Floating action button theme for dark mode
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryGreen,
        foregroundColor: neutralWhite,
        elevation: 8,
      ),

      // Bottom navigation bar theme for dark mode
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        selectedItemColor: primaryGreen,
        unselectedItemColor: neutralLightGrey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
      ),

      // Divider theme for dark mode
      dividerTheme: const DividerThemeData(
        color: neutralGrey,
        thickness: 1,
        space: 1,
      ),

      // Progress indicator theme for dark mode
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryGreen,
        linearTrackColor: Color(0xFF1E1E1E),
      ),
    );
  }
}
