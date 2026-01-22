import 'package:flutter_riverpod/flutter_riverpod.dart';

// État simple pour gérer si l'utilisateur est connecté ou non
final authProvider = StateProvider<bool>((ref) => false);
