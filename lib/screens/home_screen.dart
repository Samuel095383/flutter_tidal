import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tidal/providers/audio_provider.dart';
import 'package:flutter_tidal/providers/theme_provider.dart';
import 'package:flutter_tidal/storage/app_settings.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.settings,
    this.onNavigateToTab,
  });

  final AppSettings settings;
  final void Function(int)? onNavigateToTab;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final audio = context.watch<AudioProvider>();
    final hasTrack = audio.currentTrack != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'HiFi Music',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            onPressed: themeProvider.toggle,
            tooltip: 'Toggle theme',
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, hasTrack ? 80 : 20),
        children: [
          // Greeting
          Text(
            _greeting(),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Quick Actions
          _SectionTitle(title: 'Quick Start'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.search_rounded,
                  label: 'Search Music',
                  color: theme.colorScheme.primary,
                  onTap: () => onNavigateToTab?.call(1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.favorite_rounded,
                  label: 'Favorites',
                  color: Colors.pinkAccent,
                  onTap: () => onNavigateToTab?.call(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Server Status
          _SectionTitle(title: 'Server Status'),
          const SizedBox(height: 12),
          _ServerStatusCard(settings: settings),

          const SizedBox(height: 24),

          // How to use
          _SectionTitle(title: 'How to Use'),
          const SizedBox(height: 12),
          _InfoCard(
            items: const [
              _InfoItem(
                icon: Icons.search,
                title: 'Search',
                description: 'Find tracks by name or keyword',
              ),
              _InfoItem(
                icon: Icons.play_circle_fill,
                title: 'Play',
                description: 'Tap any track to start playing',
              ),
              _InfoItem(
                icon: Icons.favorite,
                title: 'Save',
                description: 'Save albums to your favorites',
              ),
              _InfoItem(
                icon: Icons.headphones,
                title: 'Background',
                description: 'Music keeps playing in background',
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning 🌅';
    if (hour < 17) return 'Good Afternoon ☀️';
    return 'Good Evening 🌙';
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServerStatusCard extends StatelessWidget {
  const _ServerStatusCard({required this.settings});
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseUrl = settings.apiBaseUrl;
    final isConfigured = baseUrl.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isConfigured
                    ? Colors.green.withValues(alpha: 0.15)
                    : Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isConfigured
                    ? Icons.cloud_done_rounded
                    : Icons.cloud_off_rounded,
                color: isConfigured ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    baseUrl.isEmpty
                        ? 'No Server Configured'
                        : 'Server Configured',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    baseUrl.isEmpty
                        ? 'Go to Settings to add your API URL'
                        : baseUrl,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.items});
  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: items
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          item.icon,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              item.description,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _InfoItem {
  const _InfoItem({
    required this.icon,
    required this.title,
    required this.description,
  });
  final IconData icon;
  final String title;
  final String description;
}
