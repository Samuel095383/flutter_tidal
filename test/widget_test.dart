import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tidal/models/track.dart';
import 'package:flutter_tidal/models/album.dart';
import 'package:flutter_tidal/providers/audio_provider.dart';

void main() {
  group('Track model', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 12345,
        'title': 'Test Track',
        'duration': 180,
        'version': null,
        'popularity': 80,
        'audioQuality': 'LOSSLESS',
        'explicit': false,
        'artist': {'id': 1, 'name': 'Test Artist', 'picture': null},
        'artists': [
          {'id': 1, 'name': 'Test Artist', 'picture': null}
        ],
        'album': {
          'id': 100,
          'title': 'Test Album',
          'cover': 'abcd1234-ef56-7890-abcd-ef1234567890',
        },
      };

      final track = Track.fromJson(json);

      expect(track.id, 12345);
      expect(track.title, 'Test Track');
      expect(track.duration, 180);
      expect(track.artist.name, 'Test Artist');
      expect(track.album.title, 'Test Album');
      expect(track.durationFormatted, '3:00');
      expect(track.displayTitle, 'Test Track');
    });

    test('displayTitle includes version when present', () {
      final json = {
        'id': 1,
        'title': 'Song',
        'duration': 60,
        'version': 'Remix',
        'audioQuality': 'HIGH',
        'artist': {'id': 1, 'name': 'Artist'},
        'artists': [
          {'id': 1, 'name': 'Artist'}
        ],
        'album': {'id': 1, 'title': 'Album'},
      };

      final track = Track.fromJson(json);
      expect(track.displayTitle, 'Song (Remix)');
    });
  });

  group('TrackAlbum model', () {
    test('coverUrl formats UUID correctly', () {
      final album = TrackAlbum(
        id: 1,
        title: 'Test',
        cover: 'abcd1234-ef56-7890-abcd-ef1234567890',
      );
      expect(album.coverUrl,
          'https://resources.tidal.com/images/abcd1234/ef56/7890/abcd/ef1234567890/640x640.jpg');
    });

    test('coverUrl returns null when cover is null', () {
      const album = TrackAlbum(id: 1, title: 'Test', cover: null);
      expect(album.coverUrl, isNull);
    });
  });

  group('FavoriteAlbum model', () {
    test('encode and decode roundtrip', () {
      const album = FavoriteAlbum(
        id: 42,
        title: 'My Album',
        cover: 'abc-def',
        artistName: 'Artist',
      );

      final encoded = album.encode();
      final decoded = FavoriteAlbum.decode(encoded);

      expect(decoded.id, 42);
      expect(decoded.title, 'My Album');
      expect(decoded.cover, 'abc-def');
      expect(decoded.artistName, 'Artist');
    });

    test('equality is based on id', () {
      const a = FavoriteAlbum(id: 1, title: 'A', artistName: 'X');
      const b = FavoriteAlbum(id: 1, title: 'B', artistName: 'Y');
      const c = FavoriteAlbum(id: 2, title: 'A', artistName: 'X');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('RepeatMode', () {
    test('has three values: off, all, one', () {
      expect(RepeatMode.values.length, 3);
      expect(RepeatMode.values, contains(RepeatMode.off));
      expect(RepeatMode.values, contains(RepeatMode.all));
      expect(RepeatMode.values, contains(RepeatMode.one));
    });

    test('off is the first value (default)', () {
      expect(RepeatMode.values.first, RepeatMode.off);
    });
  });
}
