import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart'; // Ensure kIsWeb is available
// Removed: import 'dart:io';

import '../../../../core/theme/app_colors.dart';
import '../widgets/hba1c_card.dart';
import '../widgets/glucose_chart.dart';
import '../widgets/tir_card.dart';
import '../widgets/glucose_stats_card.dart'; // Import du nouveau widget
import '../../glucose/glucose_provider.dart'; // Import du provider
import 'package:diaside_mobile/core/constants/api_constants.dart'; // Import ApiConfig

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  double? _serverHbA1c;
  Map<String, dynamic>? _tirStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHbA1c();
    _fetchTIR();
    _autoSyncMedtrum();
  }

  Future<void> _fetchHbA1c() async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'jwt_token');
      if (token == null) return;

      final dio = Dio();
      
      final response = await dio.get(
        '${ApiConfig.baseUrl}/api/stats/hba1c', // Use ApiConfig.baseUrl
        options: Options(headers: {'Authorization': 'Bearer $token'})
      );
      print('DEBUG: HbA1c API Response: ${response.data}'); // DEBUG PRINT

      if (response.statusCode == 200 && response.data['estimated_hba1c'] != null) {
        if (mounted) {
          setState(() {
            _serverHbA1c = response.data['estimated_hba1c'];
            print('DEBUG: _serverHbA1c set to: $_serverHbA1c'); // DEBUG PRINT
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
        print('DEBUG: HbA1c data not found or status code not 200.'); // DEBUG PRINT
      }
    } catch (e) {
      print("Erreur HbA1c: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchTIR() async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'jwt_token');
      if (token == null) return;

      final dio = Dio();
      final response = await dio.get(
        '${ApiConfig.baseUrl}/api/stats/tir', // Use ApiConfig.baseUrl
        options: Options(headers: {'Authorization': 'Bearer $token'})
      );
      print('DEBUG: TIR API Response: ${response.data}'); // DEBUG PRINT

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _tirStats = response.data;
            print('DEBUG: _tirStats set to: $_tirStats'); // DEBUG PRINT
          });
        }
      }
    } catch (e) {
      print("Erreur TIR: $e");
    }
  }

  Future<void> _autoSyncMedtrum() async {
    const storage = FlutterSecureStorage();
    final user = await storage.read(key: 'medtrum_user');
    final pass = await storage.read(key: 'medtrum_pass');
    
    if (user != null && pass != null) {
      try {
        final token = await storage.read(key: 'jwt_token');
        final dio = Dio();
        await dio.post(
          '${ApiConfig.baseUrl}/api/medtrum/connect', // Use ApiConfig.baseUrl
          data: {'username': user, 'password': pass, 'region': 'fr'},
          options: Options(headers: {'Authorization': 'Bearer $token'})
        );
        // Refresh Data
        if (mounted) {
          _fetchHbA1c();
          _fetchTIR();
          ref.invalidate(glucoseProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Synchronisation Medtrum effectuée ✅"), duration: Duration(seconds: 2))
          );
        }
      } catch (e) {
        print("Auto-Sync Error: $e");
      }
    }
  }

  String _getMotivationalMessage(double hba1c, double target) {
    double diff = hba1c - target;
    if (diff <= 0) return "C\'est exceptionnel ! 🎉\nVous êtes dans la cible. Continuez ainsi, votre corps vous remercie !";
    if (diff <= 0.5) return "Presque parfait ! 💪\nVous y êtes presque. Encore un tout petit effort pour stabiliser.";
    if (diff <= 1.5) return "Bon travail ! 📈\nVous progressez. Chaque petite action positive compte pour descendre encore.";
    return "On ne lâche rien ! ❤️\nLe diabète est un marathon. Concentrez-vous sur aujourd\'hui, nous sommes là pour vous aider.";
  }

  @override
  Widget build(BuildContext context) {
    final glucoseEntries = ref.watch(glucoseProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('DIASIDE', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 1.5)),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary), 
            onPressed: _fetchHbA1c
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text("Bonjour, Joan 👋", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            
            // HbA1c Card
            if (_serverHbA1c != null)
              HbA1cCard(
                currentEstimated: _serverHbA1c!,
                target: 7.0,
                lastLabResult: null, 
                targetDate: DateTime(2026, 12, 31),
                message: _getMotivationalMessage(_serverHbA1c!, 7.0),
              ),

            // TIR Card (New) + Insight
            if (_tirStats != null) ...[
              TIRCard(
                low: (_tirStats!['low'] as num).toDouble(),
                normal: (_tirStats!['normal'] as num).toDouble(),
                high: (_tirStats!['high'] as num).toDouble(),
              ),
              if ((_tirStats!['high'] as num).toDouble() > 25.0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                        const SizedBox(width: 10),
                        Expanded(child: Text("Attention : Taux d\'hyperglycémie un peu élevé sur 24h. Soyez vigilant !", style: GoogleFonts.poppins(fontSize: 12, color: Colors.orange[800]))),
                      ],
                    ),
                  ),
                ),
            ],

            // Statistiques glycémiques calculées (Moyenne + Stabilité)
            if (glucoseEntries.isNotEmpty)
              GlucoseStatsCard(entries: glucoseEntries),

            if (_serverHbA1c == null)
              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
              else
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    children: [
                      Text("Aucune donnée HbA1c", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/medtrum'),
                        child: const Text("Synchroniser Medtrum")
                      )
                    ],
                  ),
                )
            else
              // Si données présentes, on garde le bouton accessible en bas
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(
                  child: TextButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/medtrum'),
                    icon: const Icon(Icons.sync, size: 18),
                    label: const Text("Synchronisation Manuelle"),
                    style: TextButton.styleFrom(foregroundColor: AppColors.textTertiary),
                  ),
                ),
              ),

            // Graphique
            if (glucoseEntries.isNotEmpty)
              GlucoseChart(entries: glucoseEntries)
            else
              Container(
                height: 200,
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Center(child: Text("Graphique Glycémie (Placeholder)", style: GoogleFonts.poppins(color: AppColors.primary)))
              )
          ],
        ),
      ),
    );
  }
}
