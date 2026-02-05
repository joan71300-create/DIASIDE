import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/hba1c_card.dart';
import '../widgets/glucose_chart.dart';
import '../../glucose/glucose_provider.dart'; // Import du provider

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  double? _serverHbA1c;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHbA1c();
  }

  Future<void> _fetchHbA1c() async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'jwt_token');
      if (token == null) return;

      final dio = Dio();
      String baseUrl = kIsWeb ? 'http://127.0.0.1:8000' : (Platform.isAndroid ? 'http://10.0.2.2:8000' : 'http://127.0.0.1:8000');
      
      final response = await dio.get(
        '$baseUrl/api/stats/hba1c',
        options: Options(headers: {'Authorization': 'Bearer $token'})
      );

      if (response.statusCode == 200 && response.data['estimated_hba1c'] != null) {
        if (mounted) {
          setState(() {
            _serverHbA1c = response.data['estimated_hba1c'];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Erreur HbA1c: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getMotivationalMessage(double hba1c, double target) {
    double diff = hba1c - target;
    if (diff <= 0) return "C'est exceptionnel ! 🎉\nVous êtes dans la cible. Continuez ainsi, votre corps vous remercie !";
    if (diff <= 0.5) return "Presque parfait ! 💪\nVous y êtes presque. Encore un tout petit effort pour stabiliser.";
    if (diff <= 1.5) return "Bon travail ! 📈\nVous progressez. Chaque petite action positive compte pour descendre encore.";
    return "On ne lâche rien ! ❤️\nLe diabète est un marathon. Concentrez-vous sur aujourd'hui, nous sommes là pour vous aider.";
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
            if (_serverHbA1c != null) ...[
              HbA1cCard(
                currentEstimated: _serverHbA1c!,
                target: 7.0,
                lastLabResult: null, 
                targetDate: DateTime(2026, 12, 31),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Text(
                  _getMotivationalMessage(_serverHbA1c!, 7.0),
                  style: GoogleFonts.poppins(
                    fontSize: 13, 
                    color: AppColors.textSecondary,
                    height: 1.5
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ]
            else if (_isLoading)
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
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Allez dans 'LogGlucose' > 'Connexion Medtrum'.")));
                      }, 
                      child: const Text("Synchroniser Medtrum")
                    )
                  ],
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
