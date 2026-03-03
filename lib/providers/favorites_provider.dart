import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tidal/models/album.dart';

class FavoritesProvider extends ChangeNotifier {
  static const _key = 'favorite_albums';
  final List<FavoriteAlbum> _favorites = [];

  List<FavoriteAlbum> get favorites => List.unmodifiable(_favorites);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    _favorites.clear();
    for (final encoded in list) {
      try {
        _favorites.add(FavoriteAlbum.decode(encoded));
      } catch (_) {
        // Skip malformed entries
      }
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _favorites.map((f) => f.encode()).toList();
    await prefs.setStringList(_key, list);
  }

  bool isFavorite(int albumId) {
    return _favorites.any((f) => f.id == albumId);
  }

  Future<void> toggleFavorite(FavoriteAlbum album) async {
    if (isFavorite(album.id)) {
      _favorites.removeWhere((f) => f.id == album.id);
    } else {
      _favorites.add(album);
    }
    await _save();
    notifyListeners();
  }

  Future<void> removeFavorite(int albumId) async {
    _favorites.removeWhere((f) => f.id == albumId);
    await _save();
    notifyListeners();
  }
}
