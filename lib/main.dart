import 'package:flutter/material.dart';
import 'package:stpt_arrivals/ui/application_state_widget.dart';
import 'package:stpt_arrivals/ui/cool_down_widget.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: new ThemeData(
          primarySwatch: Colors.amber,
        ),
        debugShowCheckedModeBanner: false,
        home: ApplicationStateWidget());
       // home: Container(color: Colors.green,));
//        home: Center(
//            child: Container(
//                width: 100, height: 100, child: AnimCoolDownWidget())));
  }
}

class AnimCoolDownWidget extends StatefulWidget {
  @override
  _AnimCoolDownWidgetState createState() => _AnimCoolDownWidgetState();
}

class _AnimCoolDownWidgetState extends State<AnimCoolDownWidget>
    with SingleTickerProviderStateMixin {
  AnimationController controller;

  Animation<double> animation;

  @override
  void initState() {
    controller =
        AnimationController(duration: Duration(seconds: 30), vsync: this);
    animation = Tween(begin: 1.0, end: 0.0).animate(controller);
    controller.forward();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        builder: (_, __) => CoolDownWidget(
              remaining: animation.value,
              label: "E1",
            ),
        animation: controller);
  }
}
