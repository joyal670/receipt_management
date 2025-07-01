// lib/features/home/presentation/widget/bar_chart_section.dart
import 'dart:math'; // For max function

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:receipt_management/features/home/data/model/invoice.dart';

import '../../../../constants/app_color.dart'; // Import your Invoice model

class BarChartSection extends StatelessWidget {
  final List<Invoice> invoices; // Accept invoice data

  const BarChartSection({super.key, required this.invoices});

  // Helper to parse grandTotal safely
  double _parseGrandTotal(String? totalString) {
    if (totalString == null || totalString.isEmpty) {
      return 0.0;
    }
    // Remove non-numeric characters except for the decimal point
    final cleanString = totalString.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleanString) ?? 0.0;
  }

  // Helper to aggregate data by day of the week
  Map<int, double> _aggregateDailyTotals() {
    // Initialize totals for each day (0=Monday, 1=Tuesday, ..., 6=Sunday)
    final Map<int, double> dailyTotals = {for (var i = 0; i < 7; i++) i: 0.0};

    for (final invoice in invoices) {
      if (invoice.date != null) {
        final dateTime = DateTime.tryParse(invoice.date!);
        if (dateTime != null) {
          // DateTime.weekday returns 1 for Monday, 7 for Sunday.
          // We want 0 for Monday, 6 for Sunday.
          final dayIndex = (dateTime.weekday - 1) % 7;
          final amount = _parseGrandTotal(invoice.grandTotal);
          dailyTotals[dayIndex] = (dailyTotals[dayIndex] ?? 0.0) + amount;
        }
      }
    }
    return dailyTotals;
  }

  double get _maxY {
    final dailyTotals = _aggregateDailyTotals();
    double maxTotal = 0.0;
    if (dailyTotals.values.isNotEmpty) {
      maxTotal = dailyTotals.values.reduce(max);
    }
    // Ensure maxY is at least 10 or 20 for visibility even with small amounts
    return max(maxTotal * 1.2, 20.0); // Add some padding above the max value
  }

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        barTouchData: barTouchData,
        titlesData: titlesData,
        borderData: borderData,
        barGroups: barGroups,
        gridData: const FlGridData(show: false),
        alignment: BarChartAlignment.spaceAround,
        maxY: _maxY, // Use dynamic maxY
      ),
    );
  }

  BarTouchData get barTouchData => BarTouchData(
    enabled: true, // Enable touch for tooltip
    touchTooltipData: BarTouchTooltipData(
      getTooltipColor: (group) => Colors.blueGrey, // A visible background
      tooltipPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      tooltipMargin: 8,
      getTooltipItem: (BarChartGroupData group, int groupIndex, BarChartRodData rod, int rodIndex) {
        // Format the amount as currency (you can customize this)
        // Assuming default currency for simplicity, you might want a package for real currency formatting
        final formattedAmount = rod.toY.toStringAsFixed(2);
        return BarTooltipItem(
          '₹$formattedAmount', // Example: Indian Rupee symbol
          const TextStyle(
            color: Colors.white, // White text on blueGrey background
            fontWeight: FontWeight.bold,
          ),
        );
      },
    ),
  );

  Widget getTitles(double value, TitleMeta meta) {
    final style = TextStyle(
      color: ChartThemeColors.contentColorBlue.darken(20),
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );
    String text;
    switch (value.toInt()) {
      case 0:
        text = 'Mon'; // Full day names might be better if space allows
        break;
      case 1:
        text = 'Tue';
        break;
      case 2:
        text = 'Wed';
        break;
      case 3:
        text = 'Thu';
        break;
      case 4:
        text = 'Fri';
        break;
      case 5:
        text = 'Sat';
        break;
      case 6:
        text = 'Sun';
        break;
      default:
        text = '';
        break;
    }
    return SideTitleWidget(
      space: 4,
      child: Text(text, style: style),
      meta: meta,
    );
  }

  FlTitlesData get titlesData => FlTitlesData(
    show: true,
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: getTitles),
    ),
    leftTitles: const AxisTitles(
      sideTitles: SideTitles(showTitles: false), // Hide left titles for simplicity
    ),
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
  );

  FlBorderData get borderData => FlBorderData(show: false);

  LinearGradient get _barsGradient => LinearGradient(
    colors: [ChartThemeColors.contentColorBlue.darken(20), ChartThemeColors.contentColorCyan],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );

  List<BarChartGroupData> get barGroups {
    final dailyTotals = _aggregateDailyTotals();
    return List.generate(7, (index) {
      final total = dailyTotals[index] ?? 0.0;
      return BarChartGroupData(
        x: index,
        barRods: [BarChartRodData(toY: total, gradient: _barsGradient)],
        showingTooltipIndicators: total > 0 ? [0] : [], // Only show tooltip indicator if > 0
      );
    });
  }
}
