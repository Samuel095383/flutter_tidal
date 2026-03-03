import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tidal/api/hifi_api.dart';
import 'package:flutter_tidal/providers/audio_provider.dart';
import 'package:flutter_tidal/providers/favorites_provider.dart';
import 'package:flutter_tidal/providers/theme_provider.dart';
import 'package:flutter_tidal/screens/main_shell.dart';
import 'package:flutter_tidal/storage/app_settings.dart';
import 'package:flutter_tidal/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await AppSettings.load();

  final themeProvider = ThemeProvider();
  await themeProvider.load();

  final favoritesProvider = FavoritesProvider();
  await favoritesProvider.load();

  final audioProvider = AudioProvider();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: favoritesProvider),
        ChangeNotifierProvider.value(value: audioProvider),
      ],
      child: MyApp(settings: settings),
    ),
  );
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _initAudio());
  }

  Future<void> _initAudio() async {
    if (!mounted) return;
    final audio = context.read<AudioProvider>();
    await audio.init();
    _updateApiForAudio();
  }

  void _updateApiForAudio() {
    if (_settings.apiBaseUrl.isNotEmpty) {
      final api = HifiApi(baseUrl: _settings.apiBaseUrl);
      context.read<AudioProvider>().setApi(api);
    }
  }

  Future<void> _updateBaseUrl(String baseUrl) async {
    final updated = _settings.copyWith(apiBaseUrl: baseUrl);
    await updated.save();
    setState(() => _settings = updated);
    _updateApiForAudio();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'HiFi Music',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: themeProvider.themeMode,
      home: MainShell(
        settings: _settings,
        onBaseUrlSaved: _updateBaseUrl,
      ),
    );
  }
}