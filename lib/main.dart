import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:stpt_arrivals/presentation/arrival_display_bloc.dart';
import 'package:stpt_arrivals/presentation/arrival_ui.dart';
import 'package:stpt_arrivals/services/parser/route_arrival_parser.dart';
import 'package:stpt_arrivals/services/parser/time_converter.dart';
import 'package:stpt_arrivals/services/remote_config.dart';
import 'package:stpt_arrivals/services/route_arrival_fetcher.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
        title: 'Flutter Demo',
        theme: new ThemeData(
          primarySwatch: Colors.blue,
        ),
        debugShowCheckedModeBanner: false,
        home: Scaffold(
            appBar: AppBar(title: Text("RATT Arrivals")),
            body: ArrivalDisplayWidget(886)));
  }
}

class ArrivalDisplayWidget extends StatefulWidget {
  final transporterId;

  ArrivalDisplayWidget(this.transporterId, {Key key}) : super(key: key);

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
        timeConverter,
        RouteArrivalFetcher(RouteArrivalParserImpl(timeConverter),
            RemoteConfigImpl(), Client()));
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            RaisedButton(
              child: const Text('Refresh'),
              onPressed: () => _bloc.load(widget.transporterId),
            ),
            RaisedButton(
              child: const Text('Switch Way'),
              onPressed: () => _bloc.toggleWay(),
            ),
          ],
        ),
        StreamBuilder(
          stream: _bloc.wayNameStream,
          builder: (context, snapshot) =>
              snapshot.hasData ? Text(snapshot.data) : Container(),
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
        content: Text(e.message),
        duration: Duration(seconds: 3),
      ));
    });
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
    return Stack(
      children: [
        StreamBuilder(
            stream: bloc.arrivalsStream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final arrivals = snapshot.data as List<ArrivalUI>;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListView.builder(
                        shrinkWrap: true,
                        itemCount: arrivals.length,
                        itemBuilder: (context, position) {
                          final arrival = arrivals.elementAt(position);
                          return Card(
                            child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                    "${arrival.stationName} ${arrival.time1.value}",
                                    style: TextStyle(fontSize: 14.0))),
                          );
                        }),
                  ],
                );
              } else {
                return Container();
              }
            }),
        StreamBuilder(
          stream: bloc.loadingStream,
          builder: (context, snapshot) => Opacity(
                opacity: snapshot.hasData ? (snapshot.data as bool) ? 1 : 0 : 0,
                child: CircularProgressIndicator(),
              ),
        )
      ],
    );
  }
}
