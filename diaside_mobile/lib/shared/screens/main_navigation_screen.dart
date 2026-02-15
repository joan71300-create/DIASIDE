import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/glucose/glucose_screen.dart';
import '../../features/glucose/glucose_provider.dart';
import '../../features/meals/screens/meal_capture_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/coach/screens/coach_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const GlucoseInputScreen(),
    const MealCaptureScreen(),
    const CoachScreen(),
    const ProfileScreen(),
  ];

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    // Sync Medtrum automatically when opening Glucose tab
    if (index == 1) {
      ref.read(glucoseProvider.notifier).syncMedtrumIfNeeded();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onTabChanged,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'LogGlucose',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Repas'),
          BottomNavigationBarItem(icon: Icon(Icons.psychology), label: 'Coach'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
