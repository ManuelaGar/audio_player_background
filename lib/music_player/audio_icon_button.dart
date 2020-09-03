import 'package:flutter/material.dart';

//import 'package:baobab/constants/constants.dart';

const kDarkBlue = Color(0xFF1D1E33);

class AudioIconButton extends StatelessWidget {
  AudioIconButton(
      {@required this.onTap,
      @required this.icon,
      @required this.containerSize});

  final Function onTap;
  final IconData icon;
  final double containerSize;

  @override
  Widget build(BuildContext context) {
    bool isPlayIcon = false;

    if (icon == Icons.pause || icon == Icons.play_arrow) {
      isPlayIcon = true;
    }

    double iconSize = containerSize - 20.0;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: const Alignment(0, 0),
        children: <Widget>[
          Container(
            height: containerSize,
            width: containerSize,
            margin: EdgeInsets.fromLTRB(3.0, 3.0, 3.0, 3.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  isPlayIcon ? kDarkBlue.withOpacity(0.3) : Colors.transparent,
            ),
            child: Icon(
              icon,
              size: iconSize,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
