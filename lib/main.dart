import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stpt_arrivals/ui/application_state_widget.dart';
import 'package:stpt_arrivals/ui/draggable_widget.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.grey[300], // navigation bar color
      statusBarColor: Colors.grey[400],
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.light));
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: new ThemeData(
            primarySwatch: Colors.amber, brightness: Brightness.light),
        debugShowCheckedModeBanner: false,
        home: ApplicationStateWidget());
       //  home: TestDraggableWidget());
  }
}

class TestDraggableWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
          width: 200,
          height: 200,
          color: Colors.white,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
             final rect = (Offset.zero & Size(constraints.maxWidth,
                      constraints.maxHeight));
             return Stack(
                children: [
                  DraggableWidget(
                    child: Container(color: Colors.grey,),
                    draggableWidgetSize: Size(50,50),
                    draggingBounds: rect,
                    alignment: Alignment.bottomRight,
                    padding: EdgeInsets.all(16),
                  )
                ],
              );
            },
          )),
    );
  }
}

//class AnimCoolDownWidget extends StatefulWidget {
//  @override
//  _AnimCoolDownWidgetState createState() => _AnimCoolDownWidgetState();
//}
//
//class _AnimCoolDownWidgetState extends State<AnimCoolDownWidget>
//    with SingleTickerProviderStateMixin {
//  AnimationController controller;
//
//  Animation<double> animation;
//
//  @override
//  void initState() {
//    controller =
//        AnimationController(duration: Duration(seconds: 30), vsync: this);
//    animation = Tween(begin: 1.0, end: 0.0).animate(controller);
//    controller.forward();
//    super.initState();
//  }
//
//  @override
//  void dispose() {
//    super.dispose();
//    controller.dispose();
//  }
//
//  @override
//  Widget build(BuildContext context) {
//    return AnimatedBuilder(
//        builder: (_, __) => CoolDownWidget(
//              remaining: animation.value,
//              label: "E1",
//            ),
//        animation: controller);
//  }
//}
