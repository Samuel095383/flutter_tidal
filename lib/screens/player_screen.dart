import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_tidal/providers/audio_provider.dart';
import 'package:flutter_tidal/providers/favorites_provider.dart';
import 'package:flutter_tidal/models/album.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioProvider>();
    final track = audio.currentTrack;

    if (track == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('No track playing')),
      );
    }

    final theme = Theme.of(context);
    final favorites = context.watch<FavoritesProvider>();
    final isFav = favorites.isFavorite(track.album.id);
    final coverUrl = track.album.coverUrl;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFav ? theme.colorScheme.primary : null,
            ),
            onPressed: () {
              final albumFav = FavoriteAlbum(
                id: track.album.id,
                title: track.album.title,
                cover: track.album.cover,
                artistName: track.artistNames,
              );
              favorites.toggleFavorite(albumFav);
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: theme.brightness == Brightness.dark
                ? [
                    const Color(0xFF2A2A2A),
                    const Color(0xFF121212),
                  ]
                : [
                    Colors.grey.shade300,
                    Colors.white,
                  ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 1),

                // Album Art
                Hero(
                  tag: 'album_art',
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 340),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: coverUrl != null
                            ? CachedNetworkImage(
                                imageUrl: coverUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  color: theme
                                      .colorScheme.surfaceContainerHighest,
                                  child: const Center(
                                    child: Icon(Icons.music_note, size: 64),
                                  ),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  color: theme
                                      .colorScheme.surfaceContainerHighest,
                                  child: const Center(
                                    child: Icon(Icons.music_note, size: 64),
                                  ),
                                ),
                              )
                            : Container(
                                color: theme
                                    .colorScheme.surfaceContainerHighest,
                                child: const Center(
                                  child: Icon(Icons.music_note, size: 64),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 1),

                // Track info
                Column(
                  children: [
                    Text(
                      track.displayTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      track.artistNames,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      track.album.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.textTheme.bodySmall?.color
                            ?.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Progress bar
                StreamBuilder<Duration>(
                  stream: audio.positionStream,
                  builder: (context, snapshot) {
                    final pos = snapshot.data ?? Duration.zero;
                    final dur = audio.duration;
                    final progress = dur.inMilliseconds > 0
                        ? pos.inMilliseconds / dur.inMilliseconds
                        : 0.0;

                    return Column(
                      children: [
                        SliderTheme(
                          data: theme.sliderTheme.copyWith(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 7,
                            ),
                          ),
                          child: Slider(
                            value: progress.clamp(0.0, 1.0),
                            onChanged: (value) {
                              final newPos = Duration(
                                milliseconds:
                                    (value * dur.inMilliseconds).round(),
                              );
                              audio.seek(newPos);
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(pos),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              ),
                              Text(
                                _formatDuration(dur),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Controls
                StreamBuilder<PlayerState>(
                  stream: audio.playerStateStream,
                  builder: (context, snapshot) {
                    final isLoading = snapshot.data?.processingState ==
                            ProcessingState.loading ||
                        snapshot.data?.processingState ==
                            ProcessingState.buffering;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.shuffle_rounded),
                          iconSize: 24,
                          color: theme.textTheme.bodySmall?.color,
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(
                              Icons.skip_previous_rounded),
                          iconSize: 36,
                          onPressed: audio.skipPrevious,
                        ),
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: isLoading
                              ? const Padding(
                                  padding: EdgeInsets.all(18),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: Colors.white,
                                  ),
                                )
                              : IconButton(
                                  icon: Icon(
                                    audio.isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: theme.brightness ==
                                            Brightness.dark
                                        ? Colors.black
                                        : Colors.white,
                                  ),
                                  iconSize: 36,
                                  onPressed: audio.togglePlayPause,
                                ),
                        ),
                        IconButton(
                          icon:
                              const Icon(Icons.skip_next_rounded),
                          iconSize: 36,
                          onPressed: audio.skipNext,
                        ),
                        IconButton(
                          icon: const Icon(Icons.repeat_rounded),
                          iconSize: 24,
                          color: theme.textTheme.bodySmall?.color,
                          onPressed: () {},
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Audio quality badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    track.audioQuality,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),

                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
