import 'package:flutter/material.dart';

showAlertDialog(
    BuildContext context, String content, IconData icon, Color iconColor) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      Future.delayed(Duration(seconds: 2), () {
        Navigator.of(context).pop(true);
      });
      return AlertDialog(
        content: Row(
          children: <Widget>[
            Icon(
              icon,
              color: iconColor,
            ),
            SizedBox(
              width: 10.0,
            ),
            Text(
              content,
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(10.0),
          ),
        ),
      );
    },
  );
}
