import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class CoolDownWidget extends StatelessWidget {
  final double remaining;
  final String text;

  CoolDownWidget({Key key, this.remaining, this.text = ""}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hide = remaining <= 0.0;
    var progressWidget = ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
        child: Container(
          width: 56,
          height: 56,
          child: Stack(alignment: Alignment.center, children: [
            SizedBox.expand(
                child: CircularProgressIndicator(
              value: remaining,
            )),
            Center(
                child: Text(
              text,
              style: TextStyle(fontSize: 25),
            )),
          ]),
        ),
      ),
    );
    return hide ? Container() : progressWidget;
  }
}
