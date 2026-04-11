import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:phishcatch/providers/auth_provider.dart';
import 'package:phishcatch/providers/badge_provider.dart';
import 'package:phishcatch/providers/history_provider.dart';
import 'package:phishcatch/providers/streak_provider.dart';
import 'package:phishcatch/screens/dashboard/dashboard_screen.dart';
import 'package:phishcatch/screens/learn/learn_screen.dart';
import 'package:phishcatch/screens/profile/profile_screen.dart';
import 'package:phishcatch/screens/scanner/scanner_screen.dart';
import 'package:phishcatch/theme/app_theme.dart';

class HomeScaffold extends StatefulWidget {
  const HomeScaffold({super.key});

  @override
  State<HomeScaffold> createState() => _HomeScaffoldState();
}

class _HomeScaffoldState extends State<HomeScaffold> {
  int _currentIndex = 0;
  AuthProvider? _authProvider;

  static const List<Widget> _screens = [
    ScannerScreen(),
    DashboardScreen(),
    LearnScreen(),
    ProfileScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  void initState() {
    super.initState();
    // Load user data after first frame renders and on future auth resolves.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initData();

      _authProvider = context.read<AuthProvider>();
      _authProvider!.onAuthResolved = () {
        if (mounted) {
          _initData();
        }
      };
    });
  }

  @override
  void dispose() {
    if (_authProvider?.onAuthResolved != null) {
      _authProvider!.onAuthResolved = null;
    }
    super.dispose();
  }

  Future<void> _initData() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final history = context.read<HistoryProvider>();
    final streak = context.read<StreakProvider>();
    final badges = context.read<BadgeProvider>();
    await auth.initUserData(history, streak, badges);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _AnimatedBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}

class _AnimatedBottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const _AnimatedBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final background = Theme.of(context).bottomNavigationBarTheme.backgroundColor ??
        Theme.of(context).colorScheme.surface;

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: background,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          _NavItemData(
            label: 'Scanner',
            selectedIcon: Icons.shield,
            unselectedIcon: Icons.shield_outlined,
          ),
          _NavItemData(
            label: 'Dashboard',
            selectedIcon: Icons.bar_chart,
            unselectedIcon: Icons.bar_chart_outlined,
          ),
          _NavItemData(
            label: 'Learn',
            selectedIcon: Icons.school,
            unselectedIcon: Icons.school_outlined,
          ),
          _NavItemData(
            label: 'Profile',
            selectedIcon: Icons.person,
            unselectedIcon: Icons.person_outline,
          ),
        ].asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final selected = i == currentIndex;

          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      selected ? item.selectedIcon : item.unselectedIcon,
                      size: 20,
                      color: selected ? AppColors.primary : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? AppColors.primary : AppColors.textMuted,
                    ),
                    child: Text(item.label),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NavItemData {
  final String label;
  final IconData selectedIcon;
  final IconData unselectedIcon;

  const _NavItemData({
    required this.label,
    required this.selectedIcon,
    required this.unselectedIcon,
  });
}
