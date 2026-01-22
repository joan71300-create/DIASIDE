import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class GlucoseChart extends StatelessWidget {
  const GlucoseChart({super.key});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: const FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 30),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        minX: 0,
        maxX: 7,
        minY: 50,
        maxY: 200,
        lineBarsData: [
          LineChartBarData(
            spots: const [
              FlSpot(0, 95),
              FlSpot(1, 110),
              FlSpot(2, 105),
              FlSpot(3, 130),
              FlSpot(4, 125),
              FlSpot(5, 115),
              FlSpot(6, 100),
            ],
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }
}
