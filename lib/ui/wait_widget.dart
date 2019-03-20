import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class WaitWidget extends StatelessWidget {
  final bool showingIf;

  WaitWidget({this.showingIf = true});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: showingIf ? 1.0 : 0.0,
      child: Align(
          child: Text(
        "...",
        style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.amberAccent,
            fontSize: 26),
      )),
    );
  }
}
