import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';

class HbA1cCard extends StatelessWidget {
  final double currentEstimated; // eA1c
  final double target;
  final double? lastLabResult;
  final DateTime? targetDate;
  final String? message;

  const HbA1cCard({
    super.key,
    required this.currentEstimated,
    required this.target,
    this.lastLabResult,
    this.targetDate,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    // Calcul de la progression (0.0 à 1.0)
    // Si on est à 8.2 et qu'on veut 7.0, et qu'on est descendu à 7.6
    double start = lastLabResult ?? (currentEstimated + 1.0);
    double progress = (start - currentEstimated) / (start - target);
    if (progress < 0) progress = 0;
    if (progress > 1) progress = 1;

    // Couleur dynamique
    Color statusColor = currentEstimated <= target ? Colors.green 
        : currentEstimated < (target + 0.5) ? Colors.orange 
        : Colors.redAccent;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("OBJECTIF HbA1c", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2, color: AppColors.textSecondary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(20)),
                child: Text("Cible: ${target.toStringAsFixed(1)}%", style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Jauge Circulaire
              SizedBox(
                height: 100, width: 100,
                child: Stack(
                  children: [
                    PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(value: currentEstimated, color: statusColor, radius: 12, showTitle: false),
                          PieChartSectionData(value: 14 - currentEstimated, color: AppColors.background, radius: 12, showTitle: false),
                        ],
                        startDegreeOffset: 270,
                        sectionsSpace: 0,
                        centerSpaceRadius: 35,
                      )
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(currentEstimated.toStringAsFixed(1), style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: statusColor)),
                          Text("estimé", style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textTertiary)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Détails textuels
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (lastLabResult != null) ...[
                      Text("Dernier Labo", style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textTertiary)),
                      Text("${lastLabResult!.toStringAsFixed(1)}%", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                    ],
                    Text("À atteindre pour", style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textTertiary)),
                    Text(targetDate != null ? "${targetDate!.day}/${targetDate!.month}/${targetDate!.year}" : "Fin 2026", 
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                    
                    if (message != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                        ),
                        child: Text(
                          message!,
                          style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textPrimary, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 15),
          // Formule Explicative (Optionnel)
          Text(
            "Estimé sur 90j (Formule ADAG)",
            style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textTertiary, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
