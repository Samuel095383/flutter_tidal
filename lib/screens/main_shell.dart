import 'package:flutter/material.dart';
import 'package:flutter_tidal/screens/home_screen.dart';
import 'package:flutter_tidal/screens/search_screen.dart';
import 'package:flutter_tidal/screens/favorites_screen.dart';
import 'package:flutter_tidal/settings/settings_page.dart';
import 'package:flutter_tidal/storage/app_settings.dart';
import 'package:flutter_tidal/widgets/mini_player.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.settings,
    required this.onBaseUrlSaved,
  });

  final AppSettings settings;
  final Future<void> Function(String baseUrl) onBaseUrlSaved;

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  void switchToTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        settings: widget.settings,
        onNavigateToTab: switchToTab,
      ),
      SearchScreen(settings: widget.settings),
      const FavoritesScreen(),
      SettingsPage(
        initialBaseUrl: widget.settings.apiBaseUrl,
        onSaved: widget.onBaseUrlSaved,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search_rounded),
                activeIcon: Icon(Icons.search_rounded),
                label: 'Search',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite_border_rounded),
                activeIcon: Icon(Icons.favorite_rounded),
                label: 'Favorites',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings_rounded),
                label: 'Settings',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
