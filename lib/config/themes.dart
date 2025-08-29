import 'package:flutter/material.dart';

class AppTheme {
  // Primary Colors (extracted from HTML designs)
  static const Color primaryColor = Color(0xFF0c7ff2); // Blue from HTML
  static const Color accentColor = Color(
    0xFF0a68c4,
  ); // Darker blue for hover states
  static const Color backgroundColor = Color(0xFFf8fafc); // slate-50 equivalent
  static const Color cardColor = Color(0xFFffffff); // White cards
  static const Color borderColor = Color(0xFFe2e8f0); // slate-200

  // Slate color palette (from HTML designs)
  static const Color slate50 = Color(0xFFf8fafc);
  static const Color slate100 = Color(0xFFf1f5f9);
  static const Color slate200 = Color(0xFFe2e8f0);
  static const Color slate300 = Color(0xFFcbd5e1);
  static const Color slate400 = Color(0xFF94a3b8);
  static const Color slate500 = Color(0xFF64748b);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1e293b);
  static const Color slate900 = Color(0xFF0f172a);

  // Text Colors (extracted from HTML)
  static const Color textPrimary = Color(0xFF0d141c); // Dark text from HTML
  static const Color textSecondary = Color(0xFF64748b); // slate-500
  static const Color textLight = Color(0xFFffffff);
  static const Color textMuted = Color(0xFF94a3b8); // slate-400

  // Status Colors
  static const Color success = Color(0xFF10b981); // emerald-500
  static const Color error = Color(0xFFef4444); // red-500
  static const Color warning = Color(0xFFf59e0b); // amber-500
  static const Color info = Color(0xFF0c7ff2); // Same as primary

  // Background variations
  static const Color backgroundSecondary = Color(0xFFf1f5f9); // slate-100
  static const Color surfaceColor = Color(0xFFffffff);

  // Responsive breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // Responsive spacing
  static double getHorizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return 16.0;
    if (width < tabletBreakpoint) return 24.0;
    if (width < desktopBreakpoint) return 32.0;
    return 40.0;
  }

  static double getVerticalSpacing(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return 16.0;
    if (width < tabletBreakpoint) return 20.0;
    if (width < desktopBreakpoint) return 24.0;
    return 28.0;
  }

  static double getCardPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return 12.0;
    if (width < tabletBreakpoint) return 16.0;
    return 20.0;
  }

  static double getBorderRadius(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return 12.0;
    if (width < tabletBreakpoint) return 16.0;
    return 20.0;
  }

  // Light Theme
  static final ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: accentColor,
      surface: surfaceColor,
      onPrimary: Colors.white,
      onSecondary: textPrimary,
      onSurface: textPrimary,
      error: error,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: backgroundColor,
    cardColor: cardColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundColor,
      foregroundColor: textPrimary,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: slate700),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        backgroundColor: Colors.transparent,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: slate100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: const TextStyle(color: textMuted),
    ),
    cardTheme: CardThemeData(
      color: cardColor,
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.zero,
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: primaryColor,
      unselectedLabelColor: textMuted,
      indicator: BoxDecoration(
        border: Border(bottom: BorderSide(color: primaryColor, width: 2)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 32,
      ),
      headlineMedium: TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 24,
      ),
      headlineSmall: TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 20,
      ),
      titleLarge: TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
      titleMedium: TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.w500,
        fontSize: 16,
      ),
      titleSmall: TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
      bodyMedium: TextStyle(color: textPrimary, fontSize: 14),
      bodySmall: TextStyle(color: textSecondary, fontSize: 12),
    ),
    dividerTheme: const DividerThemeData(
      color: borderColor,
      thickness: 1,
      space: 1,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor;
        }
        return textMuted;
      }),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return Colors.white;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor;
        }
        return textMuted;
      }),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryColor,
      unselectedItemColor: textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      unselectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
      ),
    ),
  );
  // Add this to your AppTheme class
  static double getResponsiveFontSize(
    BuildContext context,
    double baseFontSize,
  ) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return baseFontSize * 0.9;
    if (width < tabletBreakpoint) return baseFontSize;
    if (width < desktopBreakpoint) return baseFontSize * 1.1;
    return baseFontSize * 1.2;
  }

  static EdgeInsets getResponsiveMargin(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return const EdgeInsets.all(8.0);
    if (width < tabletBreakpoint) return const EdgeInsets.all(12.0);
    if (width < desktopBreakpoint) return const EdgeInsets.all(16.0);
    return const EdgeInsets.all(20.0);
  }
}
