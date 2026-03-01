import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  const AppSettings({required this.apiBaseUrl});

  static const _kApiBaseUrlKey = 'apiBaseUrl';

  final String apiBaseUrl;

  AppSettings copyWith({String? apiBaseUrl}) {
    return AppSettings(apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl);
  }

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString(_kApiBaseUrlKey) ?? '';
    return AppSettings(apiBaseUrl: baseUrl);
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kApiBaseUrlKey, apiBaseUrl);
  }
}
