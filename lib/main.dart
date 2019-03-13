import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:stpt_arrivals/models/transporter.dart';
import 'package:stpt_arrivals/presentation/arrival_display_bloc.dart';
import 'package:stpt_arrivals/presentation/arrival_ui.dart';
import 'package:stpt_arrivals/presentation/time_ui_converter.dart';
import 'package:stpt_arrivals/services/parser/route_arrival_parser.dart';
import 'package:stpt_arrivals/services/parser/time_converter.dart';
import 'package:stpt_arrivals/services/remote_config.dart';
import 'package:stpt_arrivals/services/restoring_cooldown_manager.dart';
import 'package:stpt_arrivals/services/route_arrival_fetcher.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
        title: 'Flutter Demo',
        theme: new ThemeData(
          primarySwatch: Colors.amber,
        ),
        debugShowCheckedModeBanner: false,
        home: SafeArea(
          child: Scaffold(
              body: ArrivalDisplayWidget(
                  Transporter(886, "40", TransporterType.bus))),
        ));
  }
}

class ArrivalDisplayWidget extends StatefulWidget {
  final Transporter transporter;

  ArrivalDisplayWidget(this.transporter, {Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => ArrivalDisplayWidgetState();
}

class ArrivalDisplayWidgetState extends State<ArrivalDisplayWidget> {
  ArrivalDisplayBloc _bloc;

  ArrivalDisplayWidgetState() {
    final timeProvider = SystemTimeProvider();
    final timeConverter = ArrivalTimeConverterImpl(timeProvider);
    _bloc = ArrivalDisplayBlocImpl(
        SystemTimeProvider(),
        TimeUIConverterImpl(),
        RouteArrivalFetcher(RouteArrivalParserImpl(timeConverter),
            RemoteConfigImpl(), Client()),
        RestoringCoolDownManagerImpl()
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_){
      _bloc.load(widget.transporter.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Material(
          elevation: 2,
          child: Container(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(left: 16),
                  padding: EdgeInsets.all(8),
                  child: Text(widget.transporter.name,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.all(Radius.circular(5.0))),
                ),
                StreamBuilder(
                  stream: _bloc.wayNameStream,
                  builder: (context, snapshot) =>
                      Expanded(child: Center(child: Text(snapshot.hasData ? snapshot.data :"??\u{2192}??"))),
                ),
                IconButton(
                  icon: Icon(Icons.timeline),
                  onPressed: () => _bloc.toggleWay(),
                ),
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: () => _bloc.load(widget.transporter.id),
                ),
              ],
            ),
          ),
        ),
        ArrivalListView(
          bloc: _bloc,
        ),
      ],
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bloc.errorStream.listen((e) {
      Scaffold.of(context).hideCurrentSnackBar();
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Padding(child: Text(e.message), padding: EdgeInsets.only(top: 24, bottom: 24),),
        duration: Duration(seconds: e.canRetry ? 15 : 3),
        action: e.canRetry
            ? SnackBarAction(
                label: "RETRY",
                onPressed: () => _bloc.load(widget.transporter.id))
            : null,
      ));
    });
  }

  @override
  void deactivate() {
    super.deactivate();
    _bloc.dispose();
  }

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }
}

class ArrivalListView extends StatelessWidget {
  final ArrivalDisplayBloc bloc;

  ArrivalListView({Key key, @required this.bloc}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Stack(
        children: [
          StreamBuilder(
              stream: bloc.arrivalsStream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final arrivals = snapshot.data as List<ArrivalUI>;
                  return ListView.builder(
                      itemCount: arrivals.length,
                      itemBuilder: (context, position) {
                        final arrival = arrivals.elementAt(position);
                        return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text("${arrival.stationName}",
                                    style: TextStyle(fontSize: 14.0)),
                                Text("${arrival.time1.value}",
                                    style: TextStyle(
                                        fontSize: 14.0,
                                        color: Color(arrival.time1.color))),
                              ],
                            ));
                      });
                } else {
                  return Container();
                }
              }),
          StreamBuilder(
            stream: bloc.loadingStream,
            builder: (context, snapshot) => Opacity(
                  opacity:
                      snapshot.hasData ? (snapshot.data as bool) ? 1 : 0 : 0,
                  child: Align(child: CircularProgressIndicator()),
                ),
          )
        ],
      ),
    );
  }
}
