import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/diaside_button.dart';
import '../../glucose/glucose_provider.dart';
import '../../../../core/constants/api_constants.dart'; // Importer ApiConfig

// Removed: import 'dart:io';

class MedtrumConnectScreen extends ConsumerStatefulWidget {
  const MedtrumConnectScreen({super.key});

  @override
  ConsumerState<MedtrumConnectScreen> createState() =>
      _MedtrumConnectScreenState();
}

class _MedtrumConnectScreenState extends ConsumerState<MedtrumConnectScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _status = "";

  Future<void> _connect() async {
    setState(() {
      _isLoading = true;
      _status = "Connexion à Medtrum...";
    });

    try {
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'jwt_token');

      // Appel API Backend en utilisant la configuration globale
      final dio = Dio();
      final baseUrl = ApiConfig.baseUrl; // Utiliser la config globale

      final response = await dio.post(
        '$baseUrl/api/medtrum/connect',
        data: {
          'username': _usernameController.text,
          'password': _passwordController.text,
          'region': 'fr',
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      setState(() {
        _status = "Succès ! ${response.data['new_entries']} mesures importées.";
        _isLoading = false;
      });

      // Save credentials for Auto-Sync
      await storage.write(key: 'medtrum_user', value: _usernameController.text);
      await storage.write(key: 'medtrum_pass', value: _passwordController.text);

      // Refresh Data
      ref.invalidate(glucoseProvider);

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _status = "Erreur: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text("Connexion Medtrum"),
        backgroundColor: AppColors.background,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              "Entrez vos identifiants EasyView pour synchroniser automatiquement vos données (90 jours).",
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: "Email EasyView",
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Mot de passe",
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 30),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              DiasideButton(label: "Synchroniser", onPressed: _connect),

            const SizedBox(height: 20),
            Text(
              _status,
              style: TextStyle(
                color: _status.startsWith("Erreur") ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
