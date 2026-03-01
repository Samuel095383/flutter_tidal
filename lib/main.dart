import 'package:flutter/material.dart';
import 'package:flutter_tidal/api/hifi_api.dart';
import 'package:flutter_tidal/settings/settings_page.dart';
import 'package:flutter_tidal/storage/app_settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await AppSettings.load();
  runApp(MyApp(settings: settings));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.settings});
  final AppSettings settings;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
  }

  Future<void> _updateBaseUrl(String baseUrl) async {
    final updated = _settings.copyWith(apiBaseUrl: baseUrl);
    await updated.save();
    setState(() => _settings = updated);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HiFi API Test Client',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: HomePage(
        settings: _settings,
        onBaseUrlSaved: _updateBaseUrl,
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.settings,
    required this.onBaseUrlSaved,
  });

  final AppSettings settings;
  final Future<void> Function(String baseUrl) onBaseUrlSaved;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _loading = false;
  String? _result;
  String? _error;

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsPage(
          initialBaseUrl: widget.settings.apiBaseUrl,
          onSaved: widget.onBaseUrlSaved,
        ),
      ),
    );

    // After returning from settings, rebuild so the displayed baseUrl updates.
    setState(() {});
  }

  Future<void> _testConnection() async {
    final baseUrl = widget.settings.apiBaseUrl;
    if (baseUrl.trim().isEmpty) {
      setState(() {
        _error = 'No API base URL set. Open Settings and save one.';
        _result = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _result = null;
      _error = null;
    });

    try {
      final api = HifiApi(baseUrl: baseUrl);
      final data = await api.getIndex();
      setState(() => _result = data.toString());
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseUrl = widget.settings.apiBaseUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('HiFi API Test Client'),
        actions: [
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Saved API Base URL:'),
          const SizedBox(height: 8),
          SelectableText(baseUrl.isEmpty ? '(not set)' : baseUrl),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loading ? null : _testConnection,
            child: Text(_loading ? 'Testing...' : 'Test connection (GET /)'),
          ),
          const SizedBox(height: 16),
          if (_error != null) Text('Error:\n$_error'),
          if (_result != null) Text('Response:\n$_result'),
        ],
      ),
    );
  }
}