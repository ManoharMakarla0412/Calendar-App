import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Core Premium Colors
  static const Color primary = Color(0xFF2563EB); // Blue
  static const Color secondary = Color(0xFF3B82F6); // Lighter Blue
  static const Color tertiary = Color(0xFF1D4ED8); // Dark Blue

  static const Color surfaceDark = Color(0xFF1C1C1E); // Elevated iOS dark surface
  static const Color backgroundDark = Color(0xFF000000); // True OLED Black
  
  static const Color surfaceLight = Color(0xFFFFFFFF); 
  static const Color backgroundLight = Color(0xFFFBFDFF); // Cool Premium Extra-White
  
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color dividerColor = Color(0xFFE2E8F0);

  static const Color error = Color(0xFFEF4444);

  // Premium Spacing System
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  // Premium Soft Shadows
  static List<BoxShadow> get softShadows => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static ThemeData lightTheme(double fontSizeFactor) => _buildTheme(Brightness.light, false, false, fontSizeFactor);
  static ThemeData darkTheme(double fontSizeFactor, bool trueBlack) => _buildTheme(Brightness.dark, false, trueBlack, fontSizeFactor);
  static ThemeData highContrastLightTheme(double fontSizeFactor) => _buildTheme(Brightness.light, true, false, fontSizeFactor);
  static ThemeData highContrastDarkTheme(double fontSizeFactor, bool trueBlack) => _buildTheme(Brightness.dark, true, trueBlack, fontSizeFactor);

  static ThemeData _buildTheme(Brightness brightness, bool highContrast, bool trueBlack, double fontSizeFactor) {
    final isDark = brightness == Brightness.dark;

    // Determine base colors
    final seedColor = highContrast ? Colors.yellowAccent : primary;
    final primaryColor = seedColor;
    final secondaryColor = highContrast ? Colors.yellowAccent : secondary;
    
    // Background and Surface
    final bgColor = isDark 
        ? (trueBlack ? Colors.black : backgroundDark) 
        : backgroundLight;
    
    final surfaceColor = isDark 
        ? (trueBlack ? const Color(0xFF1C1C1E) : surfaceDark) 
        : surfaceLight;

    // Generate ColorScheme
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: tertiary,
      surface: surfaceColor,
      error: error,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      surfaceTint: Colors.transparent, // Disable surface tint on cards for cleaner look
    );

    // Premium Typography Hierarchy
    final baseTextTheme = GoogleFonts.outfitTextTheme(isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme);
    
    // Base color for text
    final textColor = isDark ? Colors.white : textPrimary;
    final secondaryTextColor = isDark ? Colors.white70 : textSecondary;

    final textTheme = baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(fontSize: 57 * fontSizeFactor, fontWeight: FontWeight.bold, color: textColor),
      displayMedium: baseTextTheme.displayMedium?.copyWith(fontSize: 45 * fontSizeFactor, fontWeight: FontWeight.w600, color: textColor),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(fontSize: 32 * fontSizeFactor, fontWeight: FontWeight.w700, color: textColor),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(fontSize: 28 * fontSizeFactor, fontWeight: FontWeight.w600, color: textColor),
      
      // Specifically requested typography
      titleLarge: baseTextTheme.titleLarge?.copyWith(fontSize: 22 * fontSizeFactor, fontWeight: FontWeight.w600, color: textColor), // Large Title
      titleMedium: baseTextTheme.titleMedium?.copyWith(fontSize: 18 * fontSizeFactor, fontWeight: FontWeight.w600, color: textColor), // Section Title
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontSize: 16 * fontSizeFactor, color: textColor),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontSize: 14 * fontSizeFactor, fontWeight: FontWeight.w400, color: textColor), // Body
      bodySmall: baseTextTheme.bodySmall?.copyWith(fontSize: 12 * fontSizeFactor, fontWeight: FontWeight.w400, color: secondaryTextColor), // Small
      labelLarge: baseTextTheme.labelLarge?.copyWith(fontSize: 14 * fontSizeFactor, fontWeight: FontWeight.w600, color: textColor),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bgColor,
      textTheme: textTheme,
      fontFamily: GoogleFonts.outfit().fontFamily,
      
      appBarTheme: AppBarTheme(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
      ),

      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0, // Removed hard shadows for a cleaner minimal look
        shadowColor: isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.03),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
            width: 1,
          ),
        ),
      ),
      
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF000000) : Colors.white,
        elevation: 0,
        height: 70, // Slightly taller
        indicatorColor: primaryColor.withValues(alpha: isDark ? 0.20 : 0.10), 
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primaryColor, size: 26);
          }
          return IconThemeData(color: isDark ? Colors.white54 : Colors.grey[500], size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
           if (states.contains(WidgetState.selected)) {
             return TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor);
           }
           return TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? Colors.white54 : Colors.grey[500]);
        }),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: bgColor,
        indicatorColor: primaryColor.withValues(alpha: isDark ? 0.25 : 0.12),
        labelType: NavigationRailLabelType.all,
        selectedIconTheme: IconThemeData(color: primaryColor),
        unselectedIconTheme: IconThemeData(color: isDark ? Colors.white54 : Colors.grey[600]),
        selectedLabelTextStyle: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        unselectedLabelTextStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey[600]),
      ),
      
      dividerTheme: DividerThemeData(
        color: isDark ? Colors.white.withValues(alpha: 0.1) : dividerColor,
        thickness: 1,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey[50],
        hoverColor: isDark ? const Color(0xFF383838) : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDark ? Colors.transparent : Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[500]),
      ),
    );
  }
}
