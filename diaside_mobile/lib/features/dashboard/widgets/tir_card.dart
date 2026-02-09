import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class TIRCard extends StatelessWidget {
  final double low;
  final double normal;
  final double high;

  const TIRCard({
    super.key,
    required this.low,
    required this.normal,
    required this.high,
  });

  @override
  Widget build(BuildContext context) {
    // Si pas de données
    if (low == 0 && normal == 0 && high == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Temps dans la Cible (24h)",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                height: 120,
                width: 120,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: [
                      PieChartSectionData(
                        value: low,
                        color: Colors.redAccent,
                        radius: 15,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: normal,
                        color: Colors.green,
                        radius: 20, // Plus gros pour mettre en valeur
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: high,
                        color: Colors.orangeAccent,
                        radius: 15,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _buildLegendItem("Hyper (>180)", high, Colors.orangeAccent),
                    const SizedBox(height: 8),
                    _buildLegendItem("Cible (70-180)", normal, Colors.green),
                    const SizedBox(height: 8),
                    _buildLegendItem("Hypo (<70)", low, Colors.redAccent),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, double value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const Spacer(),
        Text(
          "${value.toStringAsFixed(1)}%",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
