import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;

import '../../core/theme/app_skin.dart';
import 'add_txn_screen.dart';
import 'budget_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

/// Bottom-nav container: Home / Stats / Budget / Settings.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  /// The FAB floats over the list's right edge — exactly where amounts sit —
  /// so it hides while scrolling down and returns on scroll-up or at the end.
  bool _fabVisible = true;

  static const _screens = [
    HomeScreen(),
    StatsScreen(),
    BudgetScreen(),
    SettingsScreen(),
  ];

  bool _onScroll(ScrollNotification n) {
    // Only the Home tab's own vertical list drives the FAB.
    if (_index != 0 || n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    bool? show;
    if (n is UserScrollNotification) {
      if (n.direction == ScrollDirection.reverse) show = false;
      if (n.direction == ScrollDirection.forward) show = true;
    }
    // At either end the list's bottom padding keeps rows clear of the FAB.
    if (n is ScrollEndNotification && n.metrics.atEdge) show = true;
    if (show != null && show != _fabVisible) setState(() => _fabVisible = show!);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    Icon sel(IconData i) => Icon(i, color: skin.primary);
    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: IndexedStack(index: _index, children: _screens),
      ),
      floatingActionButton: _index == 0
          ? AnimatedSlide(
              offset: _fabVisible ? Offset.zero : const Offset(0, 2),
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: AnimatedOpacity(
                opacity: _fabVisible ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: FloatingActionButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddTxnScreen()),
                  ),
                  backgroundColor: skin.primary,
                  foregroundColor: skin.onPrimary,
                  elevation: skin.shadows ? null : 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(skin.isFoodDelivery ? skin.radiusCard : 18),
                  ),
                  child: const Icon(Icons.add, size: 28),
                ),
              ),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        // Coming back to Home always shows the add button.
        onDestinationSelected: (i) => setState(() {
          _index = i;
          _fabVisible = true;
        }),
        indicatorColor: skin.isFoodDelivery ? Colors.transparent : skin.primarySoft,
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: sel(Icons.home_rounded),
              label: 'Home'),
          NavigationDestination(
              icon: const Icon(Icons.pie_chart_outline),
              selectedIcon: sel(Icons.pie_chart_rounded),
              label: 'Stats'),
          NavigationDestination(
              icon: const Icon(Icons.savings_outlined),
              selectedIcon: sel(Icons.savings_rounded),
              label: 'Budget'),
          NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: sel(Icons.settings_rounded),
              label: 'Settings'),
        ],
      ),
    );
  }
}
