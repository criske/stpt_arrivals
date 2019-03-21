import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:stpt_arrivals/models/transporter.dart';
import 'package:stpt_arrivals/presentation/arrivals/arrival_display_bloc.dart';
import 'package:stpt_arrivals/presentation/arrivals/arrival_ui.dart';
import 'package:stpt_arrivals/presentation/arrivals/time_ui_converter.dart';
import 'package:stpt_arrivals/services/parser/route_arrival_parser.dart';
import 'package:stpt_arrivals/services/parser/time_converter.dart';
import 'package:stpt_arrivals/services/route_arrival_fetcher.dart';
import 'package:stpt_arrivals/ui/application_state_widget.dart';
import 'package:stpt_arrivals/ui/wait_widget.dart';

class ArrivalDisplayScreen extends StatefulWidget {
  final Transporter transporter;

  ArrivalDisplayScreen(this.transporter, {Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ArrivalDisplayScreenState();
}

class _ArrivalDisplayScreenState extends State<ArrivalDisplayScreen> {
  ArrivalDisplayBloc _bloc;

  _ArrivalDisplayScreenState() : super();

  @override
  void initState() {
    super.initState();
    var stateWidget = ApplicationStateWidget.of(context);

    final timeProvider = stateWidget.bloc.timeProvider;
    final timeConverter = ArrivalTimeConverterImpl(timeProvider);
    final restoringCoolDownManager = stateWidget.bloc.coolDownManager;

    final config = ApplicationStateWidget.config;
    final client = ApplicationStateWidget.client;

    _bloc = ArrivalDisplayBlocImpl(
        timeProvider,
        TimeUIConverterImpl(),
        RouteArrivalFetcher(
            RouteArrivalParserImpl(timeConverter), config, client),
        restoringCoolDownManager);

    WidgetsBinding.instance.addPostFrameCallback((_) {
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
                InkWell(
                  child: Container(
                    margin: EdgeInsets.only(left: 16, right: 8),
                    padding: EdgeInsets.all(8),
                    child: ConstrainedBox(
                      child: Center(
                        child: Text(widget.transporter.name,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ),
                      constraints: BoxConstraints(minWidth: 20, maxHeight: 20),
                    ),
                    decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.all(Radius.circular(5.0))),
                  ),
                  onTap: () => Navigator.of(context).pop(),
                ),
                StreamBuilder(
                  stream: _bloc.wayNameStream,
                  builder: (context, snapshot) => Expanded(
                          child: Center(
                              child: AutoSizeText(
                        snapshot.hasData ? snapshot.data : "??\u{2192}??",
                        style: TextStyle(
                            color: Colors.black87, fontWeight: FontWeight.bold),
                        maxFontSize: 20,
                        minFontSize: 10,
                        maxLines: 1,
                      ))),
                ),
                IconButton(
                  icon: Icon(Icons.timeline),
                  onPressed: () => _bloc.toggleWay(),
                ),
              ],
            ),
          ),
        ),
        _ArrivalListView(
          bloc: _bloc,
          transporterId: widget.transporter.id,
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

class _ArrivalListView extends StatelessWidget {
  final ArrivalDisplayBloc bloc;
  final String transporterId;

  _ArrivalListView({Key key, @required this.bloc, @required this.transporterId})
      : super(key: key);

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
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: RefreshIndicator(
                      child: ListView.separated(
                          separatorBuilder: (context, index) => Divider(
                                color: Colors.black26,
                              ),
                          itemCount: arrivals.length,
                          itemBuilder: (context, position) {
                            final arrival = arrivals.elementAt(position);
                            return Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 4, horizontal: 16),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text("${arrival.stationName}",
                                        style: TextStyle(fontSize: 14.0)),
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                          color: Color(
                                              arrival.time1.backgroundColor),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(5))),
                                      child: Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: Text(
                                          "${arrival.time1.value}",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: Color(arrival.time1.color),
                                              fontSize: 14.0),
                                        ),
                                      ),
                                    )
                                  ],
                                ));
                          }),
                      onRefresh: () => _refresh(context),
                    ),
                  );
                } else {
                  return Container();
                }
              }),
          StreamBuilder(
            stream: bloc.loadingStream,
            builder: (context, snapshot) => WaitWidget(
                  showingIf: !snapshot.hasData || snapshot.data,
                ),
          )
        ],
      ),
    );
  }

  Future<void> _refresh(BuildContext context) async {
    ApplicationStateWidget.of(context)
        .tryAction(context, "", () => bloc.load(transporterId));
  }
}
