import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profil")),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            ref.read(authProvider.notifier).state = false;
          },
          child: const Text("Se déconnecter"),
        ),
      ),
    );
  }
}
