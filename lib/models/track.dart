class TrackArtist {
  final int id;
  final String name;
  final String? picture;

  const TrackArtist({required this.id, required this.name, this.picture});

  factory TrackArtist.fromJson(Map<String, dynamic> json) {
    return TrackArtist(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Unknown',
      picture: json['picture'] as String?,
    );
  }

  String? get pictureUrl {
    if (picture == null) return null;
    final path = picture!.replaceAll('-', '/');
    return 'https://resources.tidal.com/images/$path/320x320.jpg';
  }
}

class TrackAlbum {
  final int id;
  final String title;
  final String? cover;

  const TrackAlbum({required this.id, required this.title, this.cover});

  factory TrackAlbum.fromJson(Map<String, dynamic> json) {
    return TrackAlbum(
      id: json['id'] as int,
      title: json['title'] as String? ?? 'Unknown Album',
      cover: json['cover'] as String?,
    );
  }

  String? get coverUrl {
    if (cover == null) return null;
    final path = cover!.replaceAll('-', '/');
    return 'https://resources.tidal.com/images/$path/640x640.jpg';
  }

  String? get coverUrlSmall {
    if (cover == null) return null;
    final path = cover!.replaceAll('-', '/');
    return 'https://resources.tidal.com/images/$path/160x160.jpg';
  }
}

class Track {
  final int id;
  final String title;
  final int duration;
  final String? version;
  final int? popularity;
  final String? copyright;
  final String audioQuality;
  final TrackArtist artist;
  final List<TrackArtist> artists;
  final TrackAlbum album;
  final bool explicit;

  const Track({
    required this.id,
    required this.title,
    required this.duration,
    this.version,
    this.popularity,
    this.copyright,
    required this.audioQuality,
    required this.artist,
    required this.artists,
    required this.album,
    this.explicit = false,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    final artistJson = json['artist'] as Map<String, dynamic>?;
    final artistsList = json['artists'] as List<dynamic>?;

    return Track(
      id: json['id'] as int,
      title: json['title'] as String? ?? 'Unknown',
      duration: json['duration'] as int? ?? 0,
      version: json['version'] as String?,
      popularity: json['popularity'] as int?,
      copyright: json['copyright'] as String?,
      audioQuality: json['audioQuality'] as String? ?? 'LOSSLESS',
      artist: artistJson != null
          ? TrackArtist.fromJson(artistJson)
          : const TrackArtist(id: 0, name: 'Unknown'),
      artists: artistsList
              ?.map((e) => TrackArtist.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      album: json['album'] != null
          ? TrackAlbum.fromJson(json['album'] as Map<String, dynamic>)
          : const TrackAlbum(id: 0, title: 'Unknown Album'),
      explicit: json['explicit'] as bool? ?? false,
    );
  }

  String get displayTitle {
    if (version != null && version!.isNotEmpty) {
      return '$title ($version)';
    }
    return title;
  }

  String get artistNames => artists.map((a) => a.name).join(', ');

  String get durationFormatted {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
