import 'dart:convert';

class FavoriteAlbum {
  final int id;
  final String title;
  final String? cover;
  final String artistName;

  const FavoriteAlbum({
    required this.id,
    required this.title,
    this.cover,
    required this.artistName,
  });

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

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'cover': cover,
        'artistName': artistName,
      };

  factory FavoriteAlbum.fromJson(Map<String, dynamic> json) {
    return FavoriteAlbum(
      id: json['id'] as int,
      title: json['title'] as String,
      cover: json['cover'] as String?,
      artistName: json['artistName'] as String,
    );
  }

  String encode() => jsonEncode(toJson());

  static FavoriteAlbum decode(String source) =>
      FavoriteAlbum.fromJson(jsonDecode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FavoriteAlbum &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
