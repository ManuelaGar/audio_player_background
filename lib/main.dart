import 'package:audio_player_background/music_player/music_player_screen.dart';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio Service Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: AudioServiceWidget(child: FirstScreen()),
    );
  }
}

class FirstScreen extends StatefulWidget {
  static const id = 'select_meditation_screen';
  @override
  _FirstScreenState createState() => _FirstScreenState();
}

class _FirstScreenState extends State<FirstScreen> {
  String currentRecording = 'Waiting Meditation';
  String currentPhase = 'Surgery';
  String currentRecordingFormatted = 'waiting_meditation';
  String kUrl =
      'https://firebasestorage.googleapis.com/v0/b/boabab-24f46.appspot.com/o/songs%2Fplaylist_en%2Fsurgery%2Fwaiting_meditation.mp3?alt=media&token=f31e9b21-32b5-4d06-9042-0645136f9eb1';
  String bgImage = 'amor_divino';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Background audio app'),
      ),
      body: Container(
        child: Center(
          child: MaterialButton(
            color: Colors.green,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlayMusicScreen(
                    selectedRecording: currentRecording,
                    selectedPhase: currentPhase,
                    selectedRecordingFormatted: currentRecordingFormatted,
                    kUrl: kUrl,
                    backgroundImage: bgImage,
                    originScreen: FirstScreen.id,
                  ),
                ),
              );
            },
            child: Text('Next screen'),
          ),
        ),
      ),
    );
  }
}
