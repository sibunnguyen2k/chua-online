import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../services/leaderboard_api.dart';
import 'home_screen.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart';
import 'shrine_screen.dart';
import 'wooden_fish_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _index = 0;
  final Set<int> _visited = {0}; // chỉ dựng tab khi lần đầu mở

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      AppScope.read(context).flushTaps(); // không mất lượt gõ khi thoát app
    }
  }

  void _select(int i) => setState(() {
        _index = i;
        _visited.add(i);
      });

  Widget _page(int i) {
    if (!_visited.contains(i)) return const SizedBox.shrink();
    return switch (i) {
      0 => HomeScreen(onSelectTab: _select),
      1 => const WoodenFishScreen(),
      2 => const ShrineScreen(),
      3 => LeaderboardScreen(
          api: LeaderboardApi(AppScope.read(context).api.client)),
      _ => const ProfileScreen(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
          index: _index, children: [for (var i = 0; i < 5; i++) _page(i)]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Trang chủ'),
          NavigationDestination(
              icon: Icon(Icons.radio_button_unchecked),
              selectedIcon: Icon(Icons.circle),
              label: 'Gõ mõ'),
          NavigationDestination(
              icon: Icon(Icons.temple_buddhist_outlined),
              selectedIcon: Icon(Icons.temple_buddhist_rounded),
              label: 'Điện thờ'),
          NavigationDestination(
              icon: Icon(Icons.emoji_events_outlined),
              selectedIcon: Icon(Icons.emoji_events_rounded),
              label: 'Xếp hạng'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Cá nhân'),
        ],
      ),
    );
  }
}
