import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tidal/providers/theme_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.initialBaseUrl,
    required this.onSaved,
  });

  final String initialBaseUrl;
  final Future<void> Function(String baseUrl) onSaved;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialBaseUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _normalizeBaseUrl(String input) {
    var v = input.trim();
    if (v.endsWith('/')) v = v.substring(0, v.length - 1);
    return v;
  }

  Future<void> _save() async {
    final normalized = _normalizeBaseUrl(_controller.text);

    if (normalized.isEmpty) {
      setState(() => _error = 'Please enter a base URL.');
      return;
    }

    final toStore = normalized.startsWith('http') ? normalized : 'http://$normalized';

    setState(() => _error = null);
    await widget.onSaved(toStore);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Appearance section
          Text(
            'Appearance',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Icon(
                themeProvider.isDark
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
              ),
              title: const Text('Dark Mode'),
              subtitle: Text(themeProvider.isDark ? 'Enabled' : 'Disabled'),
              trailing: Switch(
                value: themeProvider.isDark,
                onChanged: (_) => themeProvider.toggle(),
                activeColor: theme.colorScheme.primary,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Server section
          Text(
            'API Server',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Base URL',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'http://192.168.1.10:8000',
                      errorText: _error,
                      prefixIcon: const Icon(Icons.link_rounded),
                    ),
                    keyboardType: TextInputType.url,
                    onSubmitted: (_) => _save(),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // About section
          Text(
            'About',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('App Version'),
                  subtitle: const Text('1.0.0'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.api_rounded),
                  title: const Text('API Backend'),
                  subtitle: const Text('hifi-api'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}