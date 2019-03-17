import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stpt_arrivals/data/cool_down_data_source.dart';
import 'package:stpt_arrivals/models/transporter.dart';
import 'package:stpt_arrivals/presentation/application_state_bloc.dart';
import 'package:stpt_arrivals/services/parser/time_converter.dart';
import 'package:stpt_arrivals/services/restoring_cooldown_manager.dart';
import 'package:stpt_arrivals/ui/arrival_display_screen.dart';
import 'package:stpt_arrivals/ui/transporters_screen.dart';

class ApplicationStateWidget extends StatefulWidget {

  final ApplicationStateBloc bloc = ApplicationStateBloc(
      RestoringCoolDownManagerImpl(CoolDownDataSourceImpl()),
      SystemTimeProvider());

  ApplicationStateWidget({Key key}) : super(key: key);

  @override
  _ApplicationStateWidgetState createState() => _ApplicationStateWidgetState();

  static ApplicationStateWidget of(BuildContext context) {
    var inheritFromWidgetOfExactType =
        context.ancestorWidgetOfExactType(ApplicationStateWidget)
            as ApplicationStateWidget;
    return inheritFromWidgetOfExactType;
  }
}

class _ApplicationStateWidgetState extends State<ApplicationStateWidget> {

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey();

  @override
  Widget build(BuildContext context) => WillPopScope(
      onWillPop: () async {
        final navigatorState = navigatorKey.currentState;
        return navigatorState.canPop() ? !navigatorState.pop() : true;
      },
      child:Scaffold(
        body: SafeArea(
          child: Navigator(
            key: navigatorKey,
            initialRoute: "/",
            onGenerateRoute: (settings) {
              WidgetBuilder builder;
              switch (settings.name) {
                case "/":
                  builder = (BuildContext _) => TransportersScreen();
                  break;
                case "/arrivals":
                  {
                    final transporter = settings.arguments as Transporter;
                    builder = (BuildContext _) => ArrivalDisplayScreen(transporter);
                    break;
                  }
                default:
                  throw Exception('Invalid route: ${settings.name}');
              }
              return MaterialPageRoute(builder: builder, settings: settings);
            },
          ),
        ),
      ));

  @override
  void dispose() {
    widget.bloc.dispose();
    super.dispose();
  }


}
