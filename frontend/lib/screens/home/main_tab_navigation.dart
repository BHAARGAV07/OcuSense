import 'package:flutter/material.dart';
import '../../widgets/bottom_navigation.dart';
import 'home_screen.dart';
import '../track/track_screen.dart';
import '../insights/insights_screen.dart';
import '../care/care_screen.dart';
import '../profile/profile_screen.dart';

class MainTabNavigation extends StatefulWidget {
  final int initialTab;
  const MainTabNavigation({super.key, this.initialTab = 0});

  @override
  State<MainTabNavigation> createState() => _MainTabNavigationState();
}

class _MainTabNavigationState extends State<MainTabNavigation> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  final List<Widget> _screens = const [
    HomeScreen(),
    TrackScreen(),
    InsightsScreen(),
    CareScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
