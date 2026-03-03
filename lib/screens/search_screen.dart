import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tidal/api/hifi_api.dart';
import 'package:flutter_tidal/models/track.dart';
import 'package:flutter_tidal/models/album.dart';
import 'package:flutter_tidal/providers/audio_provider.dart';
import 'package:flutter_tidal/providers/favorites_provider.dart';
import 'package:flutter_tidal/storage/app_settings.dart';
import 'package:flutter_tidal/widgets/track_tile.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.settings});
  final AppSettings settings;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  List<Track> _results = [];
  bool _loading = false;
  String? _error;
  bool _hasSearched = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    final baseUrl = widget.settings.apiBaseUrl;
    if (baseUrl.isEmpty) {
      setState(() {
        _error = 'No API server configured. Please set it in Settings.';
        _results = [];
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _hasSearched = true;
    });

    try {
      final api = HifiApi(baseUrl: baseUrl);
      final results = await api.searchTracks(query);
      setState(() => _results = results);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final audio = context.watch<AudioProvider>();
    final favorites = context.watch<FavoritesProvider>();
    final hasTrack = audio.currentTrack != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Search',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Search for tracks...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _controller.clear();
                          setState(() {
                            _results = [];
                            _hasSearched = false;
                            _error = null;
                          });
                        },
                      )
                    : null,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // Results
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 48,
                                  color: theme.colorScheme.error),
                              const SizedBox(height: 16),
                              Text(
                                'Error',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      )
                    : !_hasSearched
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search_rounded,
                                  size: 80,
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Search for your favorite music',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Find tracks, artists, and more',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          )
                        : _results.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.music_off_rounded,
                                      size: 64,
                                      color: theme.textTheme.bodySmall?.color,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No results found',
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Try a different search term',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.only(
                                    bottom: hasTrack ? 80 : 16),
                                itemCount: _results.length,
                                itemBuilder: (context, index) {
                                  final track = _results[index];
                                  final isCurrentTrack =
                                      audio.currentTrack?.id == track.id;
                                  final albumFav = FavoriteAlbum(
                                    id: track.album.id,
                                    title: track.album.title,
                                    cover: track.album.cover,
                                    artistName: track.artistNames,
                                  );

                                  return TrackTile(
                                    track: track,
                                    isPlaying: isCurrentTrack,
                                    isFavorite:
                                        favorites.isFavorite(track.album.id),
                                    onTap: () {
                                      audio.playTrack(track,
                                          trackList: _results);
                                    },
                                    onFavoriteTap: () {
                                      favorites.toggleFavorite(albumFav);
                                    },
                                  );
                                },
                              ),
          ),
        ],
      ),
    );
  }
}
