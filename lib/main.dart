import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:stpt_arrivals/presentation/arrival_display_bloc.dart';
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
        body:  ArrivalDisplayBlocProvider(
            child: ArrivalDisplayWidget(886),
            bloc: ArrivalDisplayBlocProvider.blocInstance)
      )
    );
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

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return  StreamBuilder(
            stream: _bloc.streamState,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return ArrivalStateProvider(
                  child: Column(
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
                      ArrivalListView(),
                    ],
                  ),
                  state: snapshot.data as ArrivalState,
                );
              } else {
                return CircularProgressIndicator();
              }
            });
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bloc = ArrivalDisplayBlocProvider.of(context).bloc;
    _bloc.streamState.listen((state) {
      if (state.error != null) {
        var error = state.error;
        if (error is CoolDownError) {
          Scaffold.of(context).hideCurrentSnackBar();
          Scaffold.of(context).showSnackBar(SnackBar(
              content: Text(
                  "Wait ${error.remainingSeconds} seconds before refresh")));
        }
      }
    });
  }

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }
}

class ArrivalListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var state = ArrivalStateProvider.of(context).state;

    final arrivals = state.toggleableRoute.getWay().arrivals;

    return Expanded(
      child: ListView.builder(
          itemCount: arrivals.length,
          itemBuilder: (context, position) {
            final arrival = arrivals.elementAt(position);
            return Card(
              child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text("${arrival.station.name} ${arrival.time}",
                      style: TextStyle(fontSize: 14.0))),
            );
          }),
    );
  }
}

class ArrivalDisplayBlocProvider extends InheritedWidget {
  static final blocInstance = _createDefaultArrivalDisplayBloc();

  final ArrivalDisplayBloc bloc;

  ArrivalDisplayBlocProvider({Key key, Widget child, this.bloc})
      : super(key: key, child: child);

  static ArrivalDisplayBlocProvider of(BuildContext context) {
    return context.inheritFromWidgetOfExactType(ArrivalDisplayBlocProvider)
        as ArrivalDisplayBlocProvider;
  }

  static ArrivalDisplayBlocImpl _createDefaultArrivalDisplayBloc() {
    final timeProvider = SystemTimeProvider();
    final timeConverter = ArrivalTimeConverterImpl(timeProvider);
    final bloc = ArrivalDisplayBlocImpl(
        SystemTimeProvider(),
        RouteArrivalFetcher(RouteArrivalParserImpl(timeConverter),
            RemoteConfigImpl(), Client()));
    return bloc;
  }

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => true;
}

class ArrivalStateProvider extends InheritedWidget {
  final ArrivalState state;

  ArrivalStateProvider({Key key, Widget child, this.state})
      : super(key: key, child: child);

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => true;

  static ArrivalStateProvider of(BuildContext context) {
    return context.inheritFromWidgetOfExactType(ArrivalStateProvider)
        as ArrivalStateProvider;
  }
}
