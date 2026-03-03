import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tidal/providers/audio_provider.dart';
import 'package:flutter_tidal/screens/player_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioProvider>();
    final track = audio.currentTrack;

    if (track == null || !audio.isInitialized) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final coverUrl = track.album.coverUrlSmall;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PlayerScreen()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? const Color(0xFF282828)
              : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress bar
            StreamBuilder<Duration>(
              stream: audio.positionStream,
              builder: (context, snapshot) {
                final pos = snapshot.data ?? Duration.zero;
                final dur = audio.duration;
                final progress = dur.inMilliseconds > 0
                    ? pos.inMilliseconds / dur.inMilliseconds
                    : 0.0;
                return LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation(
                    theme.colorScheme.primary,
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // Album art
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: coverUrl != null
                          ? CachedNetworkImage(
                              imageUrl: coverUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: theme
                                    .colorScheme.surfaceContainerHighest,
                                child:
                                    const Icon(Icons.music_note, size: 20),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: theme
                                    .colorScheme.surfaceContainerHighest,
                                child:
                                    const Icon(Icons.music_note, size: 20),
                              ),
                            )
                          : Container(
                              color:
                                  theme.colorScheme.surfaceContainerHighest,
                              child: const Icon(Icons.music_note, size: 20),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Track info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          track.displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          track.artistNames,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Controls
                  IconButton(
                    icon: Icon(
                      audio.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 32,
                    ),
                    onPressed: audio.togglePlayPause,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
