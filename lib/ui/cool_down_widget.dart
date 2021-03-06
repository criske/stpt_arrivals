import "dart:math";
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:stpt_arrivals/ui/utils.dart';

class CoolDownWidget extends StatelessWidget {
  final double remaining;
  final String remainingText;
  final String label;
  final bool ignoreDebugMode;

  CoolDownWidget({
    Key key,
    this.label,
    this.remaining,
    this.remainingText = "",
    this.ignoreDebugMode
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hide = remaining <= 0.0;
    var progressWidget = isInDebugMode && !ignoreDebugMode ? _widgetDebugMode() : _widgetRelease();
    return hide ? Container() : progressWidget;
  }

  Widget _widgetRelease() {
    final angle = remaining * 2 * pi - pi / 2;
    final x = cos(angle);
    final y = sin(angle);
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
        child: Container(
          // color: Colors.white,
          child: Stack(alignment: Alignment.center, children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox.expand(
                  child: CircularProgressIndicator(
                value: remaining,
              )),
            ),
            Center(
                child: Text(
              remainingText,
              style: TextStyle(fontSize: 25),
            )),
            Align(
              alignment: Alignment(x, y),
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(5.0)),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: 15, maxHeight: 15),
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Text(label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                ),
              ),
            )
          ]),
        ),
      ),
    );
  }

  Widget _widgetDebugMode() {
    return  Text(
          "$remainingText - $label",
          style: TextStyle(fontSize: 18),
        );
  }
}
