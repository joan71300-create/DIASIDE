import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../../core/theme/app_colors.dart';
import '../../glucose/glucose_model.dart';

/// Widget affichant les statistiques glycémiques calculées
/// - Moyenne glycémique
/// - Coefficient de variation (stabilité)
/// - Nombre de mesures
class GlucoseStatsCard extends StatelessWidget {
  final List<GlucoseEntry> entries;

  const GlucoseStatsCard({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    // Filtrer les entrées des dernières 24h
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(hours: 24));
    
    final recentEntries = entries
        .where((e) => e.timestamp.isAfter(yesterday))
        .toList();

    if (recentEntries.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculer les statistiques
    final stats = _calculateStats(recentEntries);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Statistiques 24h",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Moyenne
              Expanded(
                child: _StatItem(
                  icon: Icons.show_chart,
                  label: "Moyenne",
                  value: "${stats['mean']!.toStringAsFixed(0)} mg/dL",
                  color: AppColors.primary,
                ),
              ),
              // Stabilité (CV)
              Expanded(
                child: _StatItem(
                  icon: Icons.favorite_border,
                  label: "Stabilité",
                  value: "${stats['cv']!.toStringAsFixed(1)}%",
                  color: _getStabilityColor(stats['cv']!),
                ),
              ),
              // Nombre de mesures
              Expanded(
                child: _StatItem(
                  icon: Icons.bloodtype_outlined,
                  label: "Mesures",
                  value: "${stats['count']}",
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Indicateur de stabilité
          _StabilityIndicator(cv: stats['cv']!),
        ],
      ),
    );
  }

  Map<String, double> _calculateStats(List<GlucoseEntry> entries) {
    if (entries.isEmpty) {
      return {'mean': 0.0, 'cv': 0.0, 'count': 0};
    }

    final values = entries.map((e) => e.value).toList();
    final n = values.length;

    // Moyenne
    final mean = values.reduce((a, b) => a + b) / n;

    // Écart-type
    final variance = values.map((v) => math.pow(v - mean, 2)).reduce((a, b) => a + b) / n;
    final stdDev = math.sqrt(variance);

    // Coefficient de variation (CV) = (écart-type / moyenne) * 100
    final cv = mean > 0 ? (stdDev / mean) * 100 : 0.0;

    return {
      'mean': mean,
      'cv': cv,
      'count': n.toDouble(),
    };
  }

  Color _getStabilityColor(double cv) {
    if (cv <= 20) return Colors.green; // Excellent
    if (cv <= 33) return Colors.orange; // Bon
    return Colors.red; // Instable
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

class _StabilityIndicator extends StatelessWidget {
  final double cv;

  const _StabilityIndicator({required this.cv});

  @override
  Widget build(BuildContext context) {
    String message;
    Color color;
    IconData icon;

    if (cv <= 20) {
      message = "Excellent ! Votre glycémie est très stable.";
      color = Colors.green;
      icon = Icons.check_circle;
    } else if (cv <= 33) {
      message = "Bon équilibre. Continuez vos efforts !";
      color = Colors.orange;
      icon = Icons.thumb_up;
    } else {
      message = "Glycémie instable. Consultez votre coach.";
      color = Colors.red;
      icon = Icons.warning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
