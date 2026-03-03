import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tidal/providers/audio_provider.dart';
import 'package:flutter_tidal/providers/favorites_provider.dart';
import 'package:flutter_tidal/models/album.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final favorites = context.watch<FavoritesProvider>();
    final audio = context.watch<AudioProvider>();
    final hasTrack = audio.currentTrack != null;
    final albums = favorites.favorites;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Favorites',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ),
      body: albums.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.favorite_border_rounded,
                    size: 80,
                    color: theme.colorScheme.primary
                        .withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No favorites yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Search for music and save albums you love',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: EdgeInsets.fromLTRB(
                  16, 16, 16, hasTrack ? 80 : 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.78,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: albums.length,
              itemBuilder: (context, index) {
                final album = albums[index];
                return _AlbumCard(
                  album: album,
                  onRemove: () => favorites.removeFavorite(album.id),
                );
              },
            ),
    );
  }
}

class _AlbumCard extends StatelessWidget {
  const _AlbumCard({required this.album, required this.onRemove});
  final FavoriteAlbum album;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coverUrl = album.coverUrl;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onLongPress: () => _showRemoveDialog(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover
            AspectRatio(
              aspectRatio: 1,
              child: coverUrl != null
                  ? CachedNetworkImage(
                      imageUrl: coverUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Center(
                          child: Icon(Icons.album, size: 48),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Center(
                          child: Icon(Icons.album, size: 48),
                        ),
                      ),
                    )
                  : Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Center(
                        child: Icon(Icons.album, size: 48),
                      ),
                    ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    album.artistName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove from favorites?'),
        content: Text('Remove "${album.title}" from your favorites?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              onRemove();
              Navigator.pop(ctx);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
