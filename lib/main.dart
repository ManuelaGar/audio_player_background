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
  @override
  _FirstScreenState createState() => _FirstScreenState();
}

class _FirstScreenState extends State<FirstScreen> {
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
                  builder: (context) => MainScreen(),
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
