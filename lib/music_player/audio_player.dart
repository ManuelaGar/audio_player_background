import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

MediaControl playControl = MediaControl(
  androidIcon: 'drawable/play_arrow',
  label: 'Play',
  action: MediaAction.play,
);

MediaControl pauseControl = MediaControl(
  androidIcon: 'drawable/pause',
  label: 'Pause',
  action: MediaAction.pause,
);

MediaControl skipToNextControl = MediaControl(
  androidIcon: 'drawable/skip_to_next',
  label: 'Next',
  action: MediaAction.skipToNext,
);

MediaControl skipToPreviousControl = MediaControl(
  androidIcon: 'drawable/skip_to_previous',
  label: 'Previous',
  action: MediaAction.skipToPrevious,
);

MediaControl stopControl = MediaControl(
  androidIcon: 'drawable/stop',
  label: 'Stop',
  action: MediaAction.stop,
);

class AudioPlayerTask extends BackgroundAudioTask {
  var _queue = <MediaItem>[];
  int _queueIndex = -1;
  AudioPlayer _audioPlayer = AudioPlayer();
  AudioProcessingState _audioProcessingState;
  bool _playing;
  bool get hasNext => _queueIndex + 1 < _queue.length;
  bool get hasPrevious => _queueIndex > 0;
  MediaItem get mediaItem => _queue[_queueIndex];

  StreamSubscription<AudioPlaybackState> _playerStateSubscription;
  StreamSubscription<AudioPlaybackEvent> _eventSubscription;

  @override
  void onStart(Map<String, dynamic> params) {
    _queue.clear();
    List mediaItems = params['data'];
    for (int i = 0; i < mediaItems.length; i++) {
      MediaItem mediaItem = MediaItem.fromJson(mediaItems[i]);
      _queue.add(mediaItem);
    }

    _playerStateSubscription = _audioPlayer.playbackStateStream
        .where((state) => state == AudioPlaybackState.completed)
        .listen((state) {
      _handlePlaybackComplete();
    });

    _eventSubscription = _audioPlayer.playbackEventStream.listen((event) {
      final bufferingState =
          event.buffering ? AudioProcessingState.buffering : null;
      switch (event.state) {
        case AudioPlaybackState.paused:
          _setState(
            processingState: bufferingState ?? AudioProcessingState.ready,
            position: event.position,
          );
          break;
        case AudioPlaybackState.playing:
          _setState(
            processingState: bufferingState ?? AudioProcessingState.ready,
            position: event.position,
          );
          break;
        case AudioPlaybackState.connecting:
          _setState(
            processingState: bufferingState ?? AudioProcessingState.connecting,
            position: event.position,
          );
          break;
        default:
      }
    });

    AudioServiceBackground.setQueue(_queue);
    onSkipToNext();
  }

  @override
  Future<void> onStop() async {
    _playing = false;
    await _audioPlayer.stop();
    await _audioPlayer.dispose();

    _playerStateSubscription.cancel();
    _eventSubscription.cancel();
    return await super.onStop();
  }

  @override
  void onPlay() {
    super.onPlay();
    if (_audioProcessingState == null) {
      _playing = true;
      _audioPlayer.play();
    }
  }

  @override
  void onPause() {
    super.onPause();
    _playing = false;
    _audioPlayer.pause();
  }

  @override
  void onSkipToQueueItem(String mediaId) {
    _audioPlayer.setUrl(mediaId);
    onPlay();
  }

  void skip(int offset) async {
    int newPos = _queueIndex + offset;
    if (newPos >= 0 && newPos < _queueIndex) {
      return;
    }
    if (_playing == null) {
      _playing = true;
    } else if (_playing) {
      await _audioPlayer.stop();
    }
    _queueIndex = newPos;
    _audioProcessingState = offset > 0
        ? AudioProcessingState.skippingToNext
        : AudioProcessingState.skippingToPrevious;
    AudioServiceBackground.setMediaItem(mediaItem);
    await _audioPlayer.setUrl(mediaItem.id);
    _audioProcessingState = null;
    if (_playing) {
      onPlay();
    } else {
      _setState(processingState: AudioProcessingState.ready);
    }
  }

  @override
  void onSkipToNext() async {
    skip(1);
  }

  @override
  void onSkipToPrevious() {
    skip(-1);
  }

  @override
  void onSeekTo(Duration position) {
    _audioPlayer.seek(position);
  }

  @override
  void onClick(MediaButton button) {
    _playPause();
  }

  @override
  void onFastForward() async {
    await _seekRelative(fastForwardInterval);
  }

  @override
  void onRewind() async {
    await _seekRelative(rewindInterval);
  }

  Future<void> _seekRelative(Duration offset) async {
    var newPosition = _audioPlayer.playbackEvent.position + offset;
    if (newPosition < Duration.zero) newPosition = Duration.zero;
    if (newPosition >= mediaItem.duration) newPosition = mediaItem.duration;
    await _audioPlayer.seek(_audioPlayer.playbackEvent.position + offset);
  }

  _handlePlaybackComplete() {
    if (hasNext) {
      onSkipToNext();
    } else {
      onStop();
    }
  }

  _playPause() {
    if (AudioServiceBackground.state.playing) {
      onPause();
    } else {
      onPlay();
    }
  }

  Future<void> _setState({
    AudioProcessingState processingState,
    Duration position,
    Duration bufferedPosition,
  }) async {
    if (position == null) {
      position = _audioPlayer.playbackEvent.position;
    }
    await AudioServiceBackground.setState(
        controls: getControls(),
        processingState:
            processingState ?? AudioServiceBackground.state.processingState,
        playing: _playing,
        position: position,
        speed: _audioPlayer.speed,
        systemActions: [MediaAction.seekTo]);
  }

  List<MediaControl> getControls() {
    if (_playing) {
      return [
        skipToPreviousControl,
        pauseControl,
        stopControl,
        skipToNextControl
      ];
    } else {
      return [
        skipToPreviousControl,
        playControl,
        stopControl,
        skipToNextControl
      ];
    }
  }
}

class AudioState {
  final List<MediaItem> queue;
  final MediaItem mediaItem;
  final PlaybackState playbackState;
  AudioState(this.queue, this.mediaItem, this.playbackState);
}
