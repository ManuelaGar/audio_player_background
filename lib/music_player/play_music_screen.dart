import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart';
import 'package:just_audio/just_audio.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';

import 'package:audio_player_background/music_player/audio_player.dart';
import 'package:audio_player_background/music_player/audio_duration_indicators.dart';
import 'package:audio_player_background/music_player/audio_icon_button.dart';
import 'package:audio_player_background/music_player/show_alert.dart';

typedef void OnError(Exception exception);
enum PlayerState { stopped, playing, paused }

const kMusicTitleTextStyle = TextStyle(
  //fontFamily: 'Poppins',
  color: Colors.white,
  fontWeight: FontWeight.w500,
  fontSize: 19.0,
);

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

  StreamSubscription _positionSubscription;
  StreamSubscription _audioPlayerStateSubscription;

  String currentRecording;
  String currentPhase;
  String currentRecordingFormatted;
  String songUrl;
  String bgImage;
  String lastScreen;
  int painBeforeValue;
  int anxietyBeforeValue;

  bool downloadEnabled = true;
  bool isDownloaded = false;
  bool isComplete = false;
  bool showSpinner = true;
  bool isFavorite = false;
  List<String> likedSongs;

  String localFilePath;

  Color activeIconColor = Colors.white;
  Color inactiveIconColor = Colors.white70;
  Color kBrandDarkBlue = Color(0xFF0066B1);

  double position = 0.0;
  double duration = 0.0;

  MediaItem audio;

  PlayerState playerState = PlayerState.stopped;
  get isPlaying => playerState == PlayerState.playing;
  get isPaused => playerState == PlayerState.paused;

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
    _findDownloadedFile().then((_) async {
      var dur = isDownloaded
          ? await _player.setFilePath(localFilePath)
          : await _player.setUrl(songUrl);
      duration = dur.inMilliseconds.toDouble();

      audio = MediaItem(
        id: isDownloaded ? localFilePath : songUrl,
        album: "Healing Presents",
        title: currentRecording,
        artist: currentPhase,
        duration: dur,
        artUri: "http://healingpresents.co/images/Logo_Healing_Big@3x.png",
      );

      var params = {
        'data': [audio.toJson(), isDownloaded ? 'local' : 'web']
      };

      await AudioService.start(
        backgroundTaskEntrypoint: _audioPlayerTaskEntryPoint,
        androidNotificationChannelName: 'Audio Service Demo',
        androidNotificationColor: 0xFF2196f3,
        androidNotificationIcon: 'mipmap/ic_launcher',
        androidEnableQueue: false,
        params: params,
      );

      setState(() => playerState = PlayerState.playing);

      _positionSubscription =
          Rx.combineLatest2<ScreenState, double, ScreenState>(
              _screenStateStream,
              Stream.periodic(Duration(milliseconds: 200)),
              (screenState, _) => screenState).listen((event) {
        if (event?.playbackState?.currentPosition != null) {
          setState(() {
            position =
                event.playbackState.currentPosition.inMilliseconds.toDouble();
          });
        }
      });

      _audioPlayerStateSubscription = _screenStateStream.listen((event) async {
        if (event?.playbackState?.processingState != null) {
          if (event.playbackState.processingState ==
                  AudioProcessingState.ready &&
              showSpinner) {
            setState(() {
              showSpinner = false;
            });
          } else if (event.playbackState.processingState ==
                  AudioProcessingState.stopped &&
              !isComplete) {
            setState(() => playerState = PlayerState.stopped);
          } else if (event.playbackState.processingState ==
                  AudioProcessingState.completed &&
              !isComplete) {
            isComplete = true;
            await AudioService.stop();
            Navigator.pop(context);
          }
        }
      }, onError: (msg) {
        setState(() {
          playerState = PlayerState.stopped;
          duration = 0.0;
          position = 0.0;
        });
      });
    });
  }

  @override
  void dispose() {
    _audioPlayerStateSubscription.cancel();
    _positionSubscription.cancel();
    _player.dispose();
    super.dispose();
  }

  play() {
    AudioService.play();
    setState(() => playerState = PlayerState.playing);
  }

  pause() {
    AudioService.pause();
    setState(() => playerState = PlayerState.paused);
  }

  stop() {
    AudioService.seekTo(Duration.zero);
    AudioService.pause();
    setState(() {
      playerState = PlayerState.stopped;
      position = 0.0;
    });
  }

  Future<Uint8List> _loadFileBytes(String url, {OnError onError}) async {
    Uint8List bytes;
    try {
      bytes = await readBytes(url);
    } on ClientException {
      rethrow;
    }
    return bytes;
  }

  Future _loadFile(/*l10n*/) async {
    final bytes = await _loadFileBytes(songUrl,
        onError: (Exception exception) =>
            print('_loadFile => exception $exception'));

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$currentRecordingFormatted.mp3');

    await file.writeAsBytes(bytes);
    if (await file.exists()) {
      /*showAlertDialog(
          context, l10n.successfulDownloadAlert, Icons.check, Colors.green);*/
      setState(() {
        localFilePath = file.path;
        isDownloaded = true;
        downloadEnabled = true;
      });
      //_playLocal();
    }
  }

  Future _findDownloadedFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$currentRecordingFormatted.mp3');

    if (await file.exists()) {
      setState(() {
        localFilePath = file.path;
        isDownloaded = true;
        downloadEnabled = true;
      });
    }
  }

  Future _deleteDownloadedFile(/*l10n*/) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$currentRecordingFormatted.mp3');

    if (await file.exists()) {
      try {
        await file.delete();
        /*showAlertDialog(
            context, l10n.removeDownloadAlert, Icons.close, Colors.red);*/
        setState(() {
          isDownloaded = false;
        });
      } catch (e) {
        print(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          centerTitle: true,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: <Color>[
                  Colors.transparent,
                  Colors.black.withOpacity(0.5)
                ],
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Play Music'),
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
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('images/bg_$bgImage.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              padding: EdgeInsets.fromLTRB(15.0, 0, 15.0, 30.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.5)
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Text(
                    currentRecording,
                    textAlign: TextAlign.center,
                    style: kMusicTitleTextStyle,
                  ),
                  SizedBox(
                    height: 5.0,
                  ),
                  Text(
                    currentPhase,
                    textAlign: TextAlign.center,
                    style: kMusicTitleTextStyle,
                  ),
                  Container(
                    margin:
                        EdgeInsets.symmetric(horizontal: 0.0, vertical: 20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Expanded(
                              flex: 6,
                              child: Container(),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 55.0,
                                  child: GestureDetector(
                                    onTap: isDownloaded
                                        ? () {
                                            _deleteDownloadedFile(/*l10n*/);
                                          }
                                        : () {
                                            _loadFile(/*l10n*/);
                                            setState(() {
                                              downloadEnabled = false;
                                            });
                                          },
                                    child: Icon(
                                      isDownloaded
                                          ? Icons.cloud_done
                                          : Icons.cloud_download,
                                      color: downloadEnabled
                                          ? activeIconColor
                                          : inactiveIconColor,
                                      size: 30.0,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 5.0,
                                ),
                                AudioIconButton(
                                  onTap:
                                      isPlaying ? () => pause() : () => play(),
                                  icon: isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  containerSize: 70.0,
                                ),
                                Container(
                                  width: 55.0,
                                  child: AudioIconButton(
                                    onTap: isPlaying || isPaused
                                        ? () => stop()
                                        : null,
                                    icon: Icons.stop,
                                    containerSize: 55.0,
                                  ),
                                ),
                              ],
                            ),
                            Expanded(
                              flex: 4,
                              child: Container(),
                            ),
                            Container(
                              width: 35.0,
                              padding: EdgeInsets.only(right: 10.0),
                              child: GestureDetector(
                                onTap: () {
                                  /*FirebaseFunctions().updateUserLikedSongs(
                                      context,
                                      l10n,
                                      currentPhase,
                                      currentRecording,
                                      myLocale); */
                                  setState(() {
                                    isFavorite = !isFavorite;
                                  });
                                  /*isFavorite
                                      ? showAlertDialog(
                                      context,
                                      l10n.addedLikedSongsAlert,
                                      Icons.check,
                                      Colors.green)
                                      : showAlertDialog(
                                      context,
                                      l10n.removedLikedSongsAlert,
                                      Icons.close,
                                      Colors.green); */
                                },
                                child: Icon(
                                  isFavorite
                                      ? FontAwesomeIcons.solidHeart
                                      : FontAwesomeIcons.heart,
                                  color: isFavorite
                                      ? kBrandDarkBlue
                                      : activeIconColor,
                                  size: 25.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                        positionIndicator(),
                      ],
                    ),
                  ),
                ],
              ),
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

  Widget positionIndicator() {
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
            value: duration > position ? position : 0.0,
            onChanged: (value) {
              pos = (value / 1000).roundToDouble().toInt();
              setState(() {
                position = (value / 1000).roundToDouble();
                _dragPositionSubject.add(value);
                AudioService.seekTo(Duration(milliseconds: value.toInt()));
              });
            },
          ),
        ),
        AudioDurationIndicators(
          position: Duration(seconds: pos),
          duration: Duration(seconds: dur),
        ),
      ],
    );
  }
}

void _audioPlayerTaskEntryPoint() async {
  AudioServiceBackground.run(() => AudioPlayerTask());
}
