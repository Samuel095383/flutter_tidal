import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_tidal/api/hifi_api.dart';

/// Helper to build a mock response for /track/ with a BTS manifest.
http.Response _streamResponse(String url) {
  final manifest = base64Encode(
    utf8.encode(jsonEncode({'urls': [url]})),
  );
  return http.Response(
    jsonEncode({
      'data': {
        'manifestMimeType': 'application/vnd.tidal.bts',
        'manifest': manifest,
      }
    }),
    200,
  );
}

http.Response _forbidden() {
  return http.Response(
    jsonEncode({'detail': 'Upstream API error'}),
    403,
  );
}

void main() {
  group('HifiApi.getStreamUrl quality fallback', () {
    test('returns stream URL on first try when quality succeeds', () async {
      final client = MockClient((req) async {
        expect(req.url.queryParameters['quality'], 'LOSSLESS');
        return _streamResponse('https://stream.example.com/audio.flac');
      });

      final api = HifiApi(baseUrl: 'http://localhost', client: client);
      final url = await api.getStreamUrl(1);
      expect(url, 'https://stream.example.com/audio.flac');
    });

    test('falls back to HIGH when LOSSLESS returns 403', () async {
      final requestedQualities = <String>[];
      final client = MockClient((req) async {
        final quality = req.url.queryParameters['quality']!;
        requestedQualities.add(quality);
        if (quality == 'LOSSLESS') return _forbidden();
        return _streamResponse('https://stream.example.com/audio.aac');
      });

      final api = HifiApi(baseUrl: 'http://localhost', client: client);
      final url = await api.getStreamUrl(1);
      expect(url, 'https://stream.example.com/audio.aac');
      expect(requestedQualities, ['LOSSLESS', 'HIGH']);
    });

    test('falls back through all qualities until one succeeds', () async {
      final requestedQualities = <String>[];
      final client = MockClient((req) async {
        final quality = req.url.queryParameters['quality']!;
        requestedQualities.add(quality);
        if (quality == 'LOW') {
          return _streamResponse('https://stream.example.com/audio.mp3');
        }
        return _forbidden();
      });

      final api = HifiApi(baseUrl: 'http://localhost', client: client);
      final url = await api.getStreamUrl(1);
      expect(url, 'https://stream.example.com/audio.mp3');
      expect(requestedQualities, ['LOSSLESS', 'HIGH', 'LOW']);
    });

    test('throws when all qualities return 403', () async {
      final client = MockClient((req) async => _forbidden());

      final api = HifiApi(baseUrl: 'http://localhost', client: client);
      expect(
        () => api.getStreamUrl(1),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('HTTP 403'),
        )),
      );
    });

    test('rethrows non-403 errors immediately without fallback', () async {
      final requestedQualities = <String>[];
      final client = MockClient((req) async {
        requestedQualities.add(req.url.queryParameters['quality']!);
        return http.Response('Server Error', 500);
      });

      final api = HifiApi(baseUrl: 'http://localhost', client: client);
      expect(
        () => api.getStreamUrl(1),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('HTTP 500'),
        )),
      );
      expect(requestedQualities, ['LOSSLESS']);
    });

    test('starting from HIGH skips higher quality tiers', () async {
      final requestedQualities = <String>[];
      final client = MockClient((req) async {
        final quality = req.url.queryParameters['quality']!;
        requestedQualities.add(quality);
        if (quality == 'LOW') {
          return _streamResponse('https://stream.example.com/audio.mp3');
        }
        return _forbidden();
      });

      final api = HifiApi(baseUrl: 'http://localhost', client: client);
      final url = await api.getStreamUrl(1, quality: 'HIGH');
      expect(url, 'https://stream.example.com/audio.mp3');
      expect(requestedQualities, ['HIGH', 'LOW']);
    });
  });
}
