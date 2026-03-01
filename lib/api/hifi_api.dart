import 'dart:convert';
import 'package:http/http.dart' as http;

class HifiApi {
  HifiApi({required this.baseUrl});
  final String baseUrl;

  Uri _uri(String path) {
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$p');
  }

  Future<Map<String, dynamic>> getIndex() async {
    final resp = await http.get(_uri('/'));
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
    }
    final decoded = jsonDecode(resp.body);
    if (decoded is Map<String, dynamic>) return decoded;
    return {'data': decoded};
  }
}