import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';

/// Tiny 7-day sparkline rendered in each Market list row. Colour
/// is driven by the net change (up = primary green, down = error
/// red, flat = secondary grey).
class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.values,
    this.width = 80,
    this.height = 32,
  });

  final List<double> values;
  final double width;
  final double height;

  Color _color() {
    if (values.length < 2) return AppColors.textSecondary;
    final delta = values.last - values.first;
    if (delta > 0) return AppColors.primary;
    if (delta < 0) return AppColors.error;
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) {
      return SizedBox(width: width, height: height);
    }
    final color = _color();
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final pad = (maxV - minV) * 0.05;
    return SizedBox(
      width: width,
      height: height,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minY: minV - pad,
          maxY: maxV + pad,
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < values.length; i++)
                  FlSpot(i.toDouble(), values[i]),
              ],
              isCurved: true,
              curveSmoothness: 0.2,
              color: color,
              barWidth: 1.4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
        duration: Duration.zero,
      ),
    );
  }
}
