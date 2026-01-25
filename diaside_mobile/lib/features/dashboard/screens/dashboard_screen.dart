import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/diaside_card.dart';
import '../../../shared/widgets/diaside_circle_info.dart';
import '../widgets/glucose_chart.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Bonjour, Sophie!",
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text(
                        "Votre suivi du jour est prêt.",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const CircleAvatar(
                    radius: 25,
                    backgroundColor: AppColors.primaryTeal,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Metrics Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  DiasideCircleInfo(
                    title: "HbA1c",
                    value: "6.7%",
                    size: 100,
                  ),
                  DiasideCircleInfo(
                    title: "Moyenne",
                    value: "115",
                    size: 100,
                    color: AppColors.primaryBlue,
                  ),
                  DiasideCircleInfo(
                    title: "Stabilité",
                    value: "Bonne",
                    size: 100,
                    color: AppColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // To-Do List Section
              Text(
                "To-Do List",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              DiasideCard(
                child: Column(
                  children: [
                    _buildTodoItem(
                      icon: Icons.monitor_heart,
                      text: "Mesurer glycémie post-déjeuner",
                      onTap: () {},
                    ),
                    const Divider(),
                    _buildTodoItem(
                      icon: Icons.directions_run,
                      text: "Marcher 15 min après le dîner",
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Trends Chart
              Text(
                "Tendances récentes",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              const DiasideCard(
                padding: EdgeInsets.zero,
                child: SizedBox(
                  height: 200,
                  child: GlucoseChart(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodoItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryTeal.withAlpha((0.1 * 255).round()),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primaryTeal),
      ),
      title: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}
