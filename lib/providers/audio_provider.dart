import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_tidal/api/hifi_api.dart';
import 'package:flutter_tidal/models/track.dart';

class AudioProvider extends ChangeNotifier {
  late final AudioHandler _audioHandler;
  AudioPlayer get _player => (_audioHandler as _AppAudioHandler)._player;

  Track? _currentTrack;
  final List<Track> _queue = [];
  int _currentIndex = -1;
  bool _isInitialized = false;

  Track? get currentTrack => _currentTrack;
  List<Track> get queue => List.unmodifiable(_queue);
  int get currentIndex => _currentIndex;
  bool get isInitialized => _isInitialized;

  bool get isPlaying => _isInitialized && _player.playing;
  Duration get position =>
      _isInitialized ? _player.position : Duration.zero;
  Duration get duration =>
      _isInitialized ? (_player.duration ?? Duration.zero) : Duration.zero;
  Stream<Duration> get positionStream =>
      _isInitialized ? _player.positionStream : const Stream.empty();
  Stream<PlayerState> get playerStateStream =>
      _isInitialized ? _player.playerStateStream : const Stream.empty();

  HifiApi? _api;

  void setApi(HifiApi api) {
    _api = api;
  }

  Future<void> init() async {
    if (_isInitialized) return;
    _audioHandler = await AudioService.init(
      builder: () => _AppAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.flutter_tidal.audio',
        androidNotificationChannelName: 'Music Playback',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );
    _isInitialized = true;

    _player.playerStateStream.listen((_) => notifyListeners());
    _player.positionStream.listen((_) {});
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        skipNext();
      }
    });
    notifyListeners();
  }

  Future<void> playTrack(Track track, {List<Track>? trackList}) async {
    if (_api == null) return;
    if (!_isInitialized) await init();

    _currentTrack = track;
    if (trackList != null) {
      _queue.clear();
      _queue.addAll(trackList);
      _currentIndex = trackList.indexWhere((t) => t.id == track.id);
    } else if (!_queue.any((t) => t.id == track.id)) {
      _queue.add(track);
      _currentIndex = _queue.length - 1;
    } else {
      _currentIndex = _queue.indexWhere((t) => t.id == track.id);
    }
    notifyListeners();

    try {
      final url = await _api!.getStreamUrl(track.id);
      final mediaItem = MediaItem(
        id: track.id.toString(),
        title: track.title,
        artist: track.artistNames,
        album: track.album.title,
        duration: Duration(seconds: track.duration),
        artUri: track.album.coverUrl != null
            ? Uri.parse(track.album.coverUrl!)
            : null,
      );
      (_audioHandler as BaseAudioHandler).mediaItem.add(mediaItem);
      await _player.setUrl(url);
      _player.play();
    } catch (e) {
      debugPrint('Error playing track: $e');
    }
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (!_isInitialized) return;
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    if (!_isInitialized) return;
    await _player.seek(position);
  }

  Future<void> skipNext() async {
    if (_queue.isEmpty || _currentIndex >= _queue.length - 1) return;
    _currentIndex++;
    await playTrack(_queue[_currentIndex]);
  }

  Future<void> skipPrevious() async {
    if (_queue.isEmpty) return;
    if (_player.position.inSeconds > 3 || _currentIndex <= 0) {
      await seek(Duration.zero);
      return;
    }
    _currentIndex--;
    await playTrack(_queue[_currentIndex]);
  }

  Future<void> stop() async {
    if (!_isInitialized) return;
    await _player.stop();
    _currentTrack = null;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _player.dispose();
    }
    super.dispose();
  }
}

class _AppAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  _AppAudioHandler() {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    return super.stop();
  }
}
