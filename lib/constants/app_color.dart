import 'package:flutter/widgets.dart';

class AppColor {
  static const Color primary = Color(0xFF8D71FF);
  static const Color red = Color(0xFFB30B00);
  static const Color grey = Color(0xFF9B9EAD);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
}

// lib/constants/chart_theme_colors.dart

// Define colors specifically for the chart example
class ChartThemeColors {
  static const Color contentColorBlue = Color(0xFF2196F3);
  static const Color contentColorCyan = Color(0xFF50E4FF);
  // Add any other chart-specific colors here if needed
}

// Custom Color Extension used by the fl_chart example
extension ColorExtension on Color {
  Color darken([int percent = 10]) {
    assert(1 <= percent && percent <= 100);
    final f = 1 - percent / 100;
    return Color.fromARGB(alpha, (red * f).round(), (green * f).round(), (blue * f).round());
  }
}
