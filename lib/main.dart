import 'package:audio_player_background/music_player/music_player_screen.dart';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AudioPlayer Background',
      home: AudioServiceWidget(
        child: MusicPlayerScreen(),
      ),
    );
  }
}
