import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:stpt_arrivals/data/cool_down_data_source.dart';
import 'package:stpt_arrivals/data/favorites_data_source.dart';
import 'package:stpt_arrivals/data/history_data_source.dart';
import 'package:stpt_arrivals/data/transporters_data_source.dart';
import 'package:stpt_arrivals/data/transporters_repository.dart';
import 'package:stpt_arrivals/models/transporter.dart';
import 'package:stpt_arrivals/presentation/application_state_bloc.dart';
import 'package:stpt_arrivals/services/parser/time_converter.dart';
import 'package:stpt_arrivals/services/parser/transporter_parser.dart';
import 'package:stpt_arrivals/services/remote_config.dart';
import 'package:stpt_arrivals/services/restoring_cooldown_manager.dart';
import 'package:stpt_arrivals/services/transporters_type_fetcher.dart';
import 'package:stpt_arrivals/ui/arrival_display_screen.dart';
import 'package:stpt_arrivals/ui/cool_down_widget.dart';
import 'package:stpt_arrivals/ui/draggable_widget.dart';
import 'package:stpt_arrivals/ui/transporters_screen.dart';
import 'package:stpt_arrivals/ui/utils.dart';

class ApplicationStateWidget extends StatefulWidget {
  static final RemoteConfig config = RemoteConfigImpl();

  static final Client client = Client();

  static final TransportersRepository transporterRepository =
      TransportersRepositoryImpl(
          FavoritesDataSourceImpl(),
          TransportersDataSourceImpl(),
          HistoryDataSourceImpl(),
          TransportersTypeFetcherImpl(config, client, TransporterParserImpl()));

  final bloc = ApplicationStateBloc(
    RestoringCoolDownManagerImpl(
        CoolDownDataSourceImpl(), SystemTimeProvider()),
    SystemTimeProvider(),
    transporterRepository,
  );

  ApplicationStateWidget({Key key}) : super(key: key);

  @override
  _ApplicationStateWidgetState createState() => _ApplicationStateWidgetState();

  tryActionForTransporter(
      BuildContext context, String transporterId, VoidCallback action) async {
    bloc.switchLastCoolDown(transporterId);
    if (await bloc.isInCoolDown(transporterId)) {
      Scaffold.of(context).hideCurrentSnackBar();
      Scaffold.of(context).showSnackBar(SnackBar(
          content: Text("Mai asteptati putin..."),
          duration: Duration(seconds: 1)));
    } else {
      action();
    }
  }

  static ApplicationStateWidget of(BuildContext context) {
    var inheritFromWidgetOfExactType =
        context.ancestorWidgetOfExactType(ApplicationStateWidget)
            as ApplicationStateWidget;
    return inheritFromWidgetOfExactType;
  }
}

class _ApplicationStateWidgetState extends State<ApplicationStateWidget>
    with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey();

  @override
  Widget build(BuildContext context) => WillPopScope(onWillPop: () async {
        final navigatorState = navigatorKey.currentState;
        return navigatorState.canPop() ? !navigatorState.pop() : true;
      }, child: Scaffold(body: LayoutBuilder(builder: (ctx, c) {
        final screenSize = MediaQuery.of(ctx).size;
        final rect = (Offset.zero & screenSize);
        final start = Offset(150, 300);
        return Stack(children: [
          SafeArea(
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
                      builder =
                          (BuildContext _) => ArrivalDisplayScreen(transporter);
                      break;
                    }
                  default:
                    throw Exception('Invalid route: ${settings.name}');
                }
                return MaterialPageRoute(builder: builder, settings: settings);
              },
            ),
          ),
          DraggableWidget.simple(_buildCoolDownWidget(), start, rect)
        ]);
      })));

  Widget _buildCoolDownWidget() {
    final ignoreDebugMode = false;
    return isInDebugMode && !ignoreDebugMode
        ? Container()
        : Container(
            width: 80,
            height: 80,
            child: StreamBuilder<CoolDownUI>(
                stream: widget.bloc.remainingCoolDownStream(),
                initialData: CoolDownUI.noCoolDown,
                builder: (context, snapshot) {
                  return (snapshot.connectionState == ConnectionState.active ||
                          snapshot.hasData ||
                          snapshot.data != CoolDownUI.noCoolDown)
                      ? CoolDownWidget(
                          label: snapshot.data.transporterName,
                          remaining: snapshot.data.percent,
                          remainingText:
                              snapshot.data.remainingSeconds.toString(),
                          ignoreDebugMode: ignoreDebugMode,
                        )
                      : Container();
                }));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.bloc.switchLastCoolDown();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.bloc.dispose();
    super.dispose();
  }
}
