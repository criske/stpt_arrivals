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
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or press Run > Flutter Hot Reload in IntelliJ). Notice that the
        // counter didn't reset back to zero; the application is not restarted.
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: ArrivalDisplayBlocProvider(
          child: ArrivalDisplayWidget(886),
          bloc: ArrivalDisplayBlocProvider.blocInstance),
    );
  }
}

class ArrivalDisplayWidget extends StatelessWidget {
  final transporterId;

  ArrivalDisplayWidget(this.transporterId, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = ArrivalDisplayBlocProvider.of(context).bloc;

    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return new Scaffold(
        appBar: new AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: new Text("RATT Arrivals"),
        ),
        body: StreamBuilder(
            stream: bloc.streamResult,
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
                            onPressed: () => bloc.load(transporterId),
                          ),
                          RaisedButton(
                            child: const Text('Switch Way'),
                            onPressed: () => bloc.toggleWay(),
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
            }));
  }
}

class ArrivalListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var state = ArrivalStateProvider.of(context).state;
    if (state.flag == StateFlag.ERROR) {
      var error = state.error;
      if (error is CoolDownError) {
        print("Wait more ${error.remainingSeconds}");
        // Scaffold.of(context).showSnackBar(SnackBar(content: Text("Wait ${error.remainingSeconds} before refresh")));
      }
    }
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
