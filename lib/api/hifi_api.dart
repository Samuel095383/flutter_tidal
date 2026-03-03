import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_tidal/models/track.dart';

class HifiApi {
  HifiApi({required this.baseUrl});
  final String baseUrl;

  Uri _uri(String path, [Map<String, String>? queryParams]) {
    final p = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$baseUrl$p');
    if (queryParams != null) {
      return uri.replace(queryParameters: queryParams);
    }
    return uri;
  }

  Future<Map<String, dynamic>> _get(String path,
      [Map<String, String>? params]) async {
    final resp = await http.get(_uri(path, params));
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
    }
    final decoded = jsonDecode(resp.body);
    if (decoded is Map<String, dynamic>) return decoded;
    return {'data': decoded};
  }

  Future<Map<String, dynamic>> getIndex() async {
    return _get('/');
  }

  /// Search for tracks by query string
  Future<List<Track>> searchTracks(String query) async {
    final resp = await _get('/search/', {'s': query});
    final data = resp['data'] as Map<String, dynamic>?;
    if (data == null) return [];
    final items = data['items'] as List<dynamic>?;
    if (items == null) return [];
    return items
        .map((e) => Track.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get track info
  Future<Track> getTrackInfo(int trackId) async {
    final resp = await _get('/info/', {'id': trackId.toString()});
    final data = resp['data'] as Map<String, dynamic>?;
    if (data == null) throw Exception('No track info returned');
    return Track.fromJson(data);
  }

  /// Get track stream URL - returns the direct audio URL
  Future<String> getStreamUrl(int trackId,
      {String quality = 'LOSSLESS'}) async {
    final resp =
        await _get('/track/', {'id': trackId.toString(), 'quality': quality});
    final data = resp['data'] as Map<String, dynamic>?;
    if (data == null) throw Exception('No stream data returned');

    final manifestMimeType = data['manifestMimeType'] as String?;
    final manifestB64 = data['manifest'] as String?;
    if (manifestB64 == null) throw Exception('No manifest in response');

    final manifestStr = utf8.decode(base64Decode(manifestB64));

    if (manifestMimeType == 'application/vnd.tidal.bts') {
      final manifest = jsonDecode(manifestStr) as Map<String, dynamic>;
      final urls = manifest['urls'] as List<dynamic>?;
      if (urls == null || urls.isEmpty) {
        throw Exception('No URLs in BTS manifest');
      }
      return urls.first as String;
    } else if (manifestMimeType == 'application/dash+xml') {
      // Parse DASH manifest to extract initialization URL
      final initMatch =
          RegExp(r'initialization="([^"]+)"').firstMatch(manifestStr);
      if (initMatch != null) {
        return initMatch.group(1)!;
      }
      throw Exception('Could not parse DASH manifest');
    }

    throw Exception('Unknown manifest type: $manifestMimeType');
  }

  /// Get recommendations for a track
  Future<List<Track>> getRecommendations(int trackId) async {
    final resp =
        await _get('/recommendations/', {'id': trackId.toString()});
    final data = resp['data'] as Map<String, dynamic>?;
    if (data == null) return [];
    final items = data['items'] as List<dynamic>?;
    if (items == null) return [];
    return items.map((e) {
      final trackJson = e is Map<String, dynamic>
          ? (e['track'] as Map<String, dynamic>? ?? e)
          : e as Map<String, dynamic>;
      return Track.fromJson(trackJson);
    }).toList();
  }
}