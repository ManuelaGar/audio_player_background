import 'dart:async';
import 'dart:math';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:rxdart/rxdart.dart';

import 'package:audio_player_background/music_player/audio_player.dart';

class PlayMusicScreen extends StatefulWidget {
  PlayMusicScreen({
    @required this.selectedRecording,
    @required this.selectedPhase,
    @required this.selectedRecordingFormatted,
    @required this.kUrl,
    @required this.backgroundImage,
    @required this.originScreen,
    this.painBefore,
    this.anxietyBefore,
  });

  static const id = 'play_music_screen';

  final String selectedRecording;
  final String selectedPhase;
  final String selectedRecordingFormatted;
  final String kUrl;
  final String backgroundImage;
  final String originScreen;
  final int painBefore;
  final int anxietyBefore;

  @override
  _PlayMusicScreenState createState() => _PlayMusicScreenState();
}

class _PlayMusicScreenState extends State<PlayMusicScreen> {
  final BehaviorSubject<double> _dragPositionSubject =
      BehaviorSubject.seeded(null);
  AudioPlayer _player = new AudioPlayer();

  StreamSubscription _audioPlayerStateSubscription;

  String currentRecording;
  String currentPhase;
  String currentRecordingFormatted;
  String songUrl;
  String bgImage;
  String lastScreen;
  int painBeforeValue;
  int anxietyBeforeValue;

  bool isComplete = false;
  bool showSpinner = true;

  double position = 0.0;
  double duration = 0.0;

  MediaItem audio;

  @override
  void initState() {
    currentRecording = widget.selectedRecording;
    currentPhase = widget.selectedPhase;
    currentRecordingFormatted = widget.selectedRecordingFormatted;
    songUrl = widget.kUrl;
    bgImage = widget.backgroundImage;
    lastScreen = widget.originScreen;
    painBeforeValue = widget.painBefore;
    anxietyBeforeValue = widget.anxietyBefore;

    initAudio();
    super.initState();
  }

  initAudio() async {
    var dur = await _player.setUrl(songUrl);
    duration = dur.inMilliseconds.toDouble();

    audio = MediaItem(
      id: songUrl,
      album: "Healing Presents",
      title: currentRecording,
      artist: currentPhase,
      duration: dur,
      artUri: "http://healingpresents.co/images/Logo_Healing_Big@3x.png",
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

    _audioPlayerStateSubscription = _screenStateStream.listen((event) async {
      if (event?.playbackState?.processingState != null) {
        if (event.playbackState.processingState == AudioProcessingState.ready &&
            showSpinner) {
          setState(() {
            showSpinner = false;
          });
        } else if (event.playbackState.processingState ==
                AudioProcessingState.completed &&
            !isComplete) {
          isComplete = true;
          await AudioService.stop();
          Navigator.pop(context);
        }
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    _audioPlayerStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => true,
      child: Scaffold(
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
        body: ModalProgressHUD(
          inAsyncCall: showSpinner,
          child: Container(
            child: StreamBuilder<ScreenState>(
              stream: _screenStateStream,
              builder: (context, snapshot) {
                final screenState = snapshot.data;
                final mediaItem = screenState?.mediaItem;
                final state = screenState?.playbackState;
                final playing = state?.playing ?? false;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(currentRecording),
                    Text(currentPhase),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (playing) pauseButton() else playButton(),
                        stopButton(),
                      ],
                    ),
                    positionIndicator(mediaItem, state),
                  ],
                );
              },
            ),
          ),
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
              value: 0.0,
              onChanged: (value) {
                _dragPositionSubject.add(value);
              },
            ),
          ),
          Text('${Duration.zero}/${Duration.zero}'),
        ],
      );
    }
  }
}

void _audioPlayerTaskEntryPoint() async {
  AudioServiceBackground.run(() => AudioPlayerTask());
}
