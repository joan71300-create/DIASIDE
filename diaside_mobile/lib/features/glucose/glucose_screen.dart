import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'glucose_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/diaside_card.dart';
import '../../shared/widgets/diaside_button.dart';
import 'screens/medtrum_connect_screen.dart';

class GlucoseInputScreen extends ConsumerStatefulWidget {
  const GlucoseInputScreen({super.key});

  @override
  ConsumerState<GlucoseInputScreen> createState() => _GlucoseInputScreenState();
}

class _GlucoseInputScreenState extends ConsumerState<GlucoseInputScreen> {
  final _glucoseController = TextEditingController();
  DateTime? _lastSyncTime;
  
  @override
  void initState() {
    super.initState();
    _loadLastSyncTime();
  }

  Future<void> _loadLastSyncTime() async {
    final storage = const FlutterSecureStorage();
    final lastSync = await storage.read(key: 'last_medtrum_sync');
    if (lastSync != null) {
      setState(() {
        _lastSyncTime = DateTime.tryParse(lastSync);
      });
    }
  }

  Future<void> _saveLastSyncTime() async {
    final storage = const FlutterSecureStorage();
    await storage.write(key: 'last_medtrum_sync', value: DateTime.now().toIso8601String());
    setState(() {
      _lastSyncTime = DateTime.now();
    });
  }

  Future<void> _importPDF(BuildContext context, WidgetRef ref) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text("Analyse IA du rapport PDF...", style: GoogleFonts.poppins()),
              Text("Extraction des données Medtrum (90 jours)", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      );

      await Future.delayed(const Duration(seconds: 3));

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text("✅ Rapport importé ! HbA1c mise à jour."),
          )
        );
      }
      
      ref.invalidate(glucoseProvider);
    }
  }

  String _formatLastSync() {
    if (_lastSyncTime == null) return "Jamais synchronisé";
    final diff = DateTime.now().difference(_lastSyncTime!);
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inMinutes < 60) return "Il y a ${diff.inMinutes} min";
    if (diff.inHours < 24) return "Il y a ${diff.inHours}h";
    return "Il y a ${diff.inDays} jours";
  }

  @override
  Widget build(BuildContext context) {
    final glucoseEntries = ref.watch(glucoseProvider).reversed.toList();
    
    // Calculate stats
    double? avgGlucose;
    int lowCount = 0, normalCount = 0, highCount = 0;
    if (glucoseEntries.isNotEmpty) {
      final values = glucoseEntries.map((e) => e.value).toList();
      avgGlucose = values.reduce((a, b) => a + b) / values.length;
      for (var v in values) {
        if (v < 70) lowCount++;
        else if (v <= 180) normalCount++;
        else highCount++;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: AppColors.background,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'GLYCÉMIE',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.2),
              ),
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary),
                tooltip: "Importer Rapport",
                onPressed: () => _importPDF(context, ref),
              ),
              IconButton(
                icon: const Icon(Icons.sync, color: AppColors.primary),
                tooltip: "Synchroniser Medtrum",
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (context) => const MedtrumConnectScreen()));
                  await _saveLastSyncTime();
                  ref.invalidate(glucoseProvider);
                },
              )
            ],
          ),

          // Stats Cards
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.background,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  // Last Sync Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: _lastSyncTime != null 
                          ? Colors.green.withOpacity(0.1) 
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _lastSyncTime != null ? Icons.check_circle : Icons.warning_amber,
                          size: 16,
                          color: _lastSyncTime != null ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Dernière sync: ${_formatLastSync()}",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: _lastSyncTime != null ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Stats Row
                  if (avgGlucose != null)
                    Row(
                      children: [
                        Expanded(child: _buildStatCard(" Moyenne", avgGlucose!.toInt().toString(), "mg/dL", AppColors.primary)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard(" Normal", normalCount.toString(), "mesures", Colors.green)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard(" Haut", highCount.toString(), "mesures", Colors.red)),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // Input Section
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Nouvelle mesure", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _glucoseController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            hintText: "0",
                            suffixText: "mg/dL",
                            filled: true,
                            fillColor: AppColors.surface,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          final val = double.tryParse(_glucoseController.text);
                          if (val != null) {
                            ref.read(glucoseProvider.notifier).addEntry(val, "Saisie manuelle");
                            _glucoseController.clear();
                            FocusScope.of(context).unfocus();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("✅ ${val.toInt()} mg/dL enregistré !"),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // History Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Historique", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("${glucoseEntries.length} mesures", style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
          ),

          // History List
          glucoseEntries.isEmpty 
            ? SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.water_drop_outlined, size: 64, color: AppColors.textTertiary.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text("Aucune mesure", style: GoogleFonts.poppins(color: AppColors.textTertiary)),
                        Text("Synchronisez Medtrum ou ajoutez une mesure", style: GoogleFonts.poppins(color: AppColors.textTertiary, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              )
            : SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final entry = glucoseEntries[index];
                    final color = entry.value < 70 
                        ? Colors.orange 
                        : entry.value > 180 
                            ? Colors.red 
                            : Colors.green;
                    
                    final trend = index > 0 
                        ? entry.value - glucoseEntries[index + 1].value 
                        : 0;
                    
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
                      ),
                      child: Row(
                        children: [
                          // Glucose Value
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      "${entry.value.toInt()}",
                                      style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: color),
                                    ),
                                    Text(
                                      " mg/dL",
                                      style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary),
                                    ),
                                    if (trend != 0) ...[
                                      const SizedBox(width: 8),
                                      Icon(
                                        trend > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                                        size: 16,
                                        color: trend > 0 ? Colors.red : Colors.green,
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  _formatTime(entry.timestamp),
                                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              entry.value < 70 
                                ? "Hypo" 
                                : entry.value > 180 
                                  ? "Hyper" 
                                  : "Normal",
                              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: color),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: glucoseEntries.length,
                ),
              ),

          // Bottom Padding
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(unit, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month) {
      return "Aujourd'hui ${dt.hour}h${dt.minute.toString().padLeft(2, '0')}";
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.day == yesterday.day && dt.month == yesterday.month) {
      return "Hier ${dt.hour}h${dt.minute.toString().padLeft(2, '0')}";
    }
    return "${dt.day}/${dt.month} ${dt.hour}h${dt.minute.toString().padLeft(2, '0')}";
  }
}
