import 'package:flutter/material.dart';
import 'package:stpt_arrivals/ui/application_state_widget.dart';
import 'package:stpt_arrivals/ui/transporters_screen.dart';

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
        home: ApplicationStateWidget(child: TransportersScreen())
    );
  }
}

