import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class CoolDownWidget extends StatelessWidget {
  final double remaining;
  final String remainingText;
  final String label;

  CoolDownWidget({
    Key key,
    this.label,
    this.remaining,
    this.remainingText = "",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hide = remaining <= 0.0;
    var progressWidget = ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
        child: Container(
          width: 56,
          height: 56,
          color: Colors.white,
          child: Stack(alignment: Alignment.center, children: [
            SizedBox.expand(
                child: CircularProgressIndicator(
              value: remaining,
            )),
            Center(
                child: Text(
              remainingText,
              style: TextStyle(fontSize: 25),
            )),
            Positioned(
              top:3,
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(5.0)),
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                        color: Colors.white)),
                  ),
              ),
            )
          ]),
        ),
      ),
    );
    return hide ? Container() : progressWidget;
  }
}
