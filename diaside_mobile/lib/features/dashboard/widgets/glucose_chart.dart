import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../glucose/glucose_model.dart'; // Corrected path

class GlucoseChart extends StatelessWidget {
  final List<GlucoseEntry> entries;

  const GlucoseChart({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    // Filtrer pour n'avoir que les dernières 24h et trier
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(hours: 24));
    
    final recentEntries = entries
        .where((e) => e.timestamp.isAfter(yesterday))
        .toList();
        
    recentEntries.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (recentEntries.isEmpty) {
      return Container(
        height: 200,
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Center(child: Text("Pas de données récentes", style: GoogleFonts.poppins(color: AppColors.textTertiary))),
      );
    }

    // Préparer les spots
    List<FlSpot> spots = recentEntries.map((e) {
      return FlSpot(e.timestamp.millisecondsSinceEpoch.toDouble(), e.value);
    }).toList();

    return Container(
      height: 250,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10, bottom: 10),
            child: Text("Dernières 24h", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false), // Hide X labels for simplicity or implement properly
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minY: 40,
                maxY: 300,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withOpacity(0.1),
                    ),
                  ),
                ],
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(y: 70, color: Colors.red.withOpacity(0.2), strokeWidth: 1, dashArray: [5, 5]),
                    HorizontalLine(y: 180, color: Colors.orange.withOpacity(0.2), strokeWidth: 1, dashArray: [5, 5]),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
