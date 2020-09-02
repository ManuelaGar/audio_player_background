import 'package:flutter/material.dart';

import 'format_duration.dart';

class AudioDurationIndicators extends StatelessWidget {
  const AudioDurationIndicators({
    @required this.position,
    @required this.duration,
  });

  final Duration position;
  final Duration duration;

  static Color kNumberColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12.0, 0.0, 12.0, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            position != null
                ? formatDuration(duration > position
                        ? position
                        : Duration(seconds: 0)) ??
                    ''
                : duration != null ? formatDuration(duration) : '',
            style: TextStyle(fontSize: 13.0, color: kNumberColor),
          ),
          Text(
            position != null
                ? formatDuration(duration) ?? ''
                : duration != null ? formatDuration(duration) : '',
            style: TextStyle(fontSize: 13.0, color: kNumberColor),
          ),
        ],
      ),
    );
  }
}
