import 'dart:async';
import 'dart:math';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

import 'package:audio_player_background/music_player/audio_player.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final BehaviorSubject<double> _dragPositionSubject =
      BehaviorSubject.seeded(null);
  AudioPlayer _player = new AudioPlayer();

  double position = 0.0;
  double duration = 0.0;

  String songUrl =
      'https://s3.amazonaws.com/scifri-episodes/scifri20181123-episode.mp3';

  MediaItem audio;

  @override
  void initState() {
    initAudio();
    super.initState();
  }

  initAudio() async {
    var dur = await _player.setUrl(songUrl);
    this.duration = dur.inMilliseconds.toDouble();

    audio = MediaItem(
      id: songUrl,
      album: "Science Friday",
      title: "A Salute To Head-Scratching Science",
      artist: "Science Friday and WNYC Studios",
      duration: dur,
      artUri:
          "https://media.wnyc.org/i/1400/1400/l/80/1/ScienceFriday_WNYCStudios_1400.jpg",
    );

    var params = {
      'data': [audio.toJson()]
    };
    await AudioService.start(
      backgroundTaskEntrypoint: _audioPlayerTaskEntryPoint,
      androidNotificationChannelName: 'Audio Service Demo',
      androidNotificationColor: 0xFF2196f3,
      androidNotificationIcon: 'mipmap/ic_launcher',
      androidEnableQueue: false,
      params: params,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      appBar: AppBar(
        title: Text('Audio Service Demo'),
        leading: BackButton(
          color: Colors.white,
          onPressed: () {
            AudioService.stop();
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        child: StreamBuilder<ScreenState>(
          stream: _screenStateStream,
          builder: (context, snapshot) {
            final screenState = snapshot.data;
            final mediaItem = screenState?.mediaItem;
            final state = screenState?.playbackState;
            final processingState =
                state?.processingState ?? AudioProcessingState.none;
            final playing = state?.playing ?? false;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (mediaItem?.title != null) Text(mediaItem.title),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (playing) pauseButton() else playButton(),
                    stopButton(),
                  ],
                ),
                positionIndicator(mediaItem, state),
                Text("Processing state: " +
                    "$processingState".replaceAll(RegExp(r'^.*\.'), '')),
                StreamBuilder(
                  stream: AudioService.customEventStream,
                  builder: (context, snapshot) {
                    return Text("custom event: ${snapshot.data}");
                  },
                ),
                StreamBuilder<bool>(
                  stream: AudioService.notificationClickEventStream,
                  builder: (context, snapshot) {
                    return Text(
                      'Notification Click Status: ${snapshot.data}',
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Stream<ScreenState> get _screenStateStream =>
      Rx.combineLatest2<MediaItem, PlaybackState, ScreenState>(
          AudioService.currentMediaItemStream,
          AudioService.playbackStateStream,
          (mediaItem, playbackState) => ScreenState(mediaItem, playbackState));

  IconButton playButton() => IconButton(
        icon: Icon(Icons.play_arrow),
        iconSize: 64.0,
        onPressed: AudioService.play,
      );

  IconButton pauseButton() => IconButton(
        icon: Icon(Icons.pause),
        iconSize: 64.0,
        onPressed: AudioService.pause,
      );

  IconButton stopButton() => IconButton(
        icon: Icon(Icons.stop),
        iconSize: 64.0,
        onPressed: () {
          AudioService.seekTo(Duration.zero);
          AudioService.pause();
        },
      );

  Widget positionIndicator(MediaItem mediaItem, PlaybackState state) {
    double seekPos;
    if (state != null) {
      return StreamBuilder(
        stream: Rx.combineLatest2<double, double, double>(
            _dragPositionSubject.stream,
            Stream.periodic(Duration(milliseconds: 200)),
            (dragPosition, _) => dragPosition),
        builder: (context, snapshot) {
          position =
              snapshot.data ?? state.currentPosition.inMilliseconds.toDouble();
          int pos = (position / 1000).roundToDouble().toInt();
          int dur = (duration / 1000).roundToDouble().toInt();
          return Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white38,
                  trackHeight: 3.0,
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.0),
                  overlayShape: RoundSliderOverlayShape(overlayRadius: 13.0),
                  thumbColor: Color(0xFFE9EAFF),
                  overlayColor: Color(0xFFE9EAFF).withOpacity(0.4),
                ),
                child: Slider(
                  min: 0.0,
                  max: duration,
                  value: seekPos ?? max(0.0, min(position, duration)),
                  onChanged: (value) {
                    _dragPositionSubject.add(value);
                  },
                  onChangeEnd: (value) {
                    AudioService.seekTo(Duration(milliseconds: value.toInt()));
                    seekPos = value;
                    _dragPositionSubject.add(null);
                  },
                ),
              ),
              Text("${Duration(seconds: pos)}/${Duration(seconds: dur)}"),
            ],
          );
        },
      );
    } else {
      return Column(
        children: [
          Slider(
            min: 0.0,
            max: duration,
            value: 0.0,
            onChanged: (value) {
              _dragPositionSubject.add(value);
            },
          ),
          Text(
              '${Duration(seconds: position.toInt())}/${Duration(seconds: duration.toInt())}'),
        ],
      );
    }
  }
}

void _audioPlayerTaskEntryPoint() async {
  AudioServiceBackground.run(() => AudioPlayerTask());
}
