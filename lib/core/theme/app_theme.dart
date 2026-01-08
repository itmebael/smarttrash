import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Ultra Modern Color Palette - Cyberpunk/Neon inspired
  static const Color primaryGreen = Color(0xFF00F5A0); // Electric neon green
  static const Color lightGreen = Color(0xFF00FFB4);
  static const Color darkGreen = Color(0xFF00D4AA);
  static const Color accentGreen = Color(0xFF39FF14);
  static const Color softGreen = Color(0xFFE8FFF4);
  static const Color backgroundGreen = Color(0xFF0A0A0A);

  // Cyber Blue Palette
  static const Color secondaryBlue = Color(0xFF00B4FF);
  static const Color lightBlue = Color(0xFF00D4FF);
  static const Color darkBlue = Color(0xFF0099CC);
  static const Color softBlue = Color(0xFFE6F7FF);

  // Neon Accents
  static const Color warningOrange = Color(0xFFFF6B35);
  static const Color dangerRed = Color(0xFFFF0040);
  static const Color successGreen = Color(0xFF00FF88);
  static const Color neonPurple = Color(0xFF8B5CF6);
  static const Color neonPink = Color(0xFFFF0080);

  // Modern Dark Theme Colors
  static const Color neutralGray = Color(0xFF64748B);
  static const Color lightGray = Color(0xFF1E293B);
  static const Color darkGray = Color(0xFF0F172A);
  static const Color textGray = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textLight = Color(0xFF64748B);
  static const Color borderColor = Color(0xFF334155);
  static const Color glassBackground = Color(0x1AFFFFFF);

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF5F5F5); // Soft white background
  static const Color lightSurface = Color(0xFFFFFFFF); // White surface
  static const Color lightTextPrimary = Color(0xFF1A1A1A); // Dark text for visibility
  static const Color lightTextSecondary = Color(0xFF4A4A4A); // Dark secondary text
  static const Color lightBorder = Color(0xFFE0E0E0); // Light border
  static const Color lightGlassBackground = Color(0x80FFFFFF); // White glass effect

  // Trashcan status colors
  static const Color emptyStatus = Color(0xFF4CAF50); // Green
  static const Color halfStatus = Color(0xFFFF9800); // Orange
  static const Color fullStatus = Color(0xFFD32F2F); // Red

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        brightness: Brightness.light,
        primary: primaryGreen,
        secondary: secondaryBlue,
        surface: lightSurface,
        background: lightBackground,
        error: dangerRed,
      ),
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: lightTextPrimary,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: lightTextPrimary,
        ),
        displaySmall: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        headlineLarge: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        headlineSmall: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: lightTextPrimary,
        ),
        titleSmall: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: lightTextPrimary,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: lightTextPrimary,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: lightTextPrimary,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: lightTextSecondary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: lightTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        iconTheme: const IconThemeData(color: lightTextPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: lightTextPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ).copyWith(
          overlayColor:
              WidgetStateProperty.all(primaryGreen.withOpacity(0.1)),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightGlassBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: lightBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: lightBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: dangerRed, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: dangerRed, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        labelStyle: GoogleFonts.poppins(
          color: lightTextPrimary,
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.poppins(
          color: lightTextSecondary,
          fontSize: 14,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: primaryGreen,
        unselectedItemColor: lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: primaryGreen,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: lightTextSecondary,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        brightness: Brightness.dark,
        primary: primaryGreen,
        secondary: secondaryBlue,
        surface: darkGray,
        background: backgroundGreen,
        error: dangerRed,
      ),
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textGray,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textGray,
        ),
        displaySmall: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textGray,
        ),
        headlineLarge: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textGray,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textGray,
        ),
        headlineSmall: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textGray,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textGray,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textGray,
        ),
        titleSmall: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textGray,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textGray,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textGray,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: textSecondary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textGray,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textGray,
        ),
        iconTheme: const IconThemeData(color: textGray),
      ),
    );
  }
}

// Ultra Modern Cyberpunk Gradients
class EcoGradients {
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [AppTheme.primaryGreen, AppTheme.accentGreen, AppTheme.lightGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [AppTheme.darkGray, AppTheme.backgroundGreen, Color(0xFF1A1A1A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [AppTheme.glassBackground, Color(0x0DFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [
      AppTheme.primaryGreen,
      AppTheme.secondaryBlue,
      AppTheme.neonPurple
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [AppTheme.primaryGreen, AppTheme.accentGreen],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient neonGradient = LinearGradient(
    colors: [AppTheme.primaryGreen, AppTheme.secondaryBlue, AppTheme.neonPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0x1AFFFFFF), Color(0x0DFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient lightGlassGradient = LinearGradient(
    colors: [Color(0x80FFFFFF), Color(0x40FFFFFF)], // White glass effect
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient lightBackgroundGradient = LinearGradient(
    colors: [AppTheme.lightBackground, AppTheme.lightSurface, Color(0xFFF0F0F0)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.5, 1.0],
  );
}

// Ultra Modern Neon Shadows & Glassmorphism
class EcoShadows {
  static List<BoxShadow> get light => [
        BoxShadow(
          color: AppTheme.primaryGreen.withOpacity(0.2),
          blurRadius: 8,
          offset: const Offset(0, 2),
          spreadRadius: 0,
        ),
        BoxShadow(
          color: AppTheme.primaryGreen.withOpacity(0.1),
          blurRadius: 16,
          offset: const Offset(0, 4),
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get medium => [
        BoxShadow(
          color: AppTheme.primaryGreen.withOpacity(0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
          spreadRadius: 0,
        ),
        BoxShadow(
          color: AppTheme.secondaryBlue.withOpacity(0.2),
          blurRadius: 24,
          offset: const Offset(0, 8),
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get heavy => [
        BoxShadow(
          color: AppTheme.primaryGreen.withOpacity(0.4),
          blurRadius: 20,
          offset: const Offset(0, 8),
          spreadRadius: 0,
        ),
        BoxShadow(
          color: AppTheme.secondaryBlue.withOpacity(0.3),
          blurRadius: 40,
          offset: const Offset(0, 16),
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get neon => [
        BoxShadow(
          color: AppTheme.primaryGreen.withOpacity(0.6),
          blurRadius: 20,
          offset: const Offset(0, 0),
          spreadRadius: 0,
        ),
        BoxShadow(
          color: AppTheme.accentGreen.withOpacity(0.4),
          blurRadius: 40,
          offset: const Offset(0, 0),
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get glass => [
        BoxShadow(
          color: Colors.white.withOpacity(0.1),
          blurRadius: 20,
          offset: const Offset(0, 8),
          spreadRadius: 0,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 40,
          offset: const Offset(0, 16),
          spreadRadius: 0,
        ),
      ];
}

// Glassmorphism Effects
class GlassEffects {
  static BoxDecoration get card => BoxDecoration(
        gradient: EcoGradients.glassGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: EcoShadows.glass,
      );

  static BoxDecoration get lightCard => BoxDecoration(
        gradient: EcoGradients.lightGlassGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02), // Further reduced shadow brightness
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      );

  static BoxDecoration get button => BoxDecoration(
        gradient: EcoGradients.buttonGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: EcoShadows.neon,
      );

  static BoxDecoration get lightButton => BoxDecoration(
        gradient: EcoGradients.buttonGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static BoxDecoration get hero => BoxDecoration(
        gradient: EcoGradients.heroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: EcoShadows.heavy,
      );
}

