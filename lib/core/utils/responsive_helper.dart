import 'package:flutter/material.dart';

class ResponsiveHelper {
  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // Check screen size
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  // Get responsive padding
  static EdgeInsets getPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(12);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(16);
    } else {
      return const EdgeInsets.all(20);
    }
  }

  // Get responsive margin
  static EdgeInsets getMargin(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(8);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(12);
    } else {
      return const EdgeInsets.all(20);
    }
  }

  // Get responsive font size
  static double getTitleFontSize(BuildContext context) {
    if (isMobile(context)) {
      return 20;
    } else if (isTablet(context)) {
      return 24;
    } else {
      return 28;
    }
  }

  // Get responsive column count for grids
  static int getGridColumnCount(BuildContext context) {
    if (isMobile(context)) {
      return 1;
    } else if (isTablet(context)) {
      return 2;
    } else {
      return 4;
    }
  }

  // Get responsive card spacing
  static double getCardSpacing(BuildContext context) {
    if (isMobile(context)) {
      return 8;
    } else if (isTablet(context)) {
      return 12;
    } else {
      return 16;
    }
  }
}


