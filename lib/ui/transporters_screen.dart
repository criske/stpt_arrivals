import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';
import 'package:stpt_arrivals/data/favorites_data_source.dart';
import 'package:stpt_arrivals/data/transporters_data_source.dart';
import 'package:stpt_arrivals/data/transporters_repository.dart';
import 'package:stpt_arrivals/models/transporter.dart';
import 'package:stpt_arrivals/presentation/application_state_bloc.dart';
import 'package:stpt_arrivals/presentation/transporters/transporters_bloc.dart';
import 'package:stpt_arrivals/services/parser/transporter_parser.dart';
import 'package:stpt_arrivals/services/remote_config.dart';
import 'package:stpt_arrivals/services/transporters_type_fetcher.dart';
import 'package:stpt_arrivals/ui/application_state_widget.dart';
import 'package:stpt_arrivals/ui/arrival_display_screen.dart';
import 'package:stpt_arrivals/ui/cool_down_widget.dart';

class TransportersScreen extends StatefulWidget {
  @override
  _TransportersScreenState createState() => _TransportersScreenState();
}

class _TransportersScreenState extends State<TransportersScreen> {
  TransportersBloc _bloc;

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  var _selectedDropFilter = PrettyTransporterBlocFilter();

  _TransportersScreenState() {
    _bloc = TransportersBlocImpl(TransportersRepositoryImpl(
        FavoritesDataSourceImpl(),
        TransportersDataSourceImpl(),
        TransportersTypeFetcherImpl(
            RemoteConfigImpl(), Client(), TransporterParserImpl())));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        key: _scaffoldKey,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Material(
              elevation: 2,
              child: Container(
                height: 56,
                margin: EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: <Widget>[
                      Padding(
                          padding: EdgeInsets.all(4),
                          child: Text(
                            "Filter",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          )),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: StreamBuilder<bool>(
                              stream: _bloc.loadingStream,
                              builder: (context, snapshot) {
                                final enabled =
                                    snapshot.hasData ? !snapshot.data : false;
                                return DropdownButton<
                                        PrettyTransporterBlocFilter>(
                                    isExpanded: true,
                                    onChanged: enabled
                                        ? (PrettyTransporterBlocFilter value) {
                                            setState(() {
                                              _selectedDropFilter = value;
                                            });
                                            _bloc.showBy(value.filter);
                                          }
                                        : null,
                                    items: prettyTransporterBlocFilterValues()
                                        .map((f) => DropdownMenuItem(
                                              value: f,
                                              child: Text(f.toString()),
                                            ))
                                        .toList(),
                                    value: _selectedDropFilter);
                              }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                child: Stack(children: [
                  StreamBuilder<List<Transporter>>(
                      stream: _bloc.transportersStream,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return SingleChildScrollView(
                            child: Wrap(
                              runSpacing: 4,
                              spacing: 4,
                              children: snapshot.data
                                  .map((t) => _TransporterWidget(
                                        transporter: t,
                                        onSelect: (t) {
                                          final canRoute =
                                              !ApplicationStateWidget.of(
                                                      context)
                                                  .bloc
                                                  .isInCoolDown();
                                          if (canRoute) {
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (_) =>
                                                        ArrivalDisplayScreen(
                                                            t)));
                                          } else {
                                            Scaffold.of(context)
                                                .hideCurrentSnackBar();
                                            Scaffold.of(context)
                                                .showSnackBar(SnackBar(
                                              content: Text(
                                                  "Wait for cool down to end"),
                                              duration: Duration(seconds: 1),
                                            ));
                                          }
                                        },
                                        onFavorite: (t) {
                                          _bloc.update(t);
                                        },
                                      ))
                                  .toList(),
                            ),
                          );
                        } else {
                          return Center(child: CircularProgressIndicator());
                        }
                      }),
                  Center(
                    child: StreamBuilder<bool>(
                      stream: _bloc.loadingStream,
                      builder: (_, snapshot) {
                        return Opacity(
                          opacity: snapshot.hasData ? snapshot.data ? 1 : 0 : 1,
                          child: CircularProgressIndicator(),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: StreamBuilder<CoolDown>(
                        stream: ApplicationStateWidget.of(context)
                            .bloc
                            .remainingCoolDownStream(),
                        builder: (context, snapshot) {
                          return snapshot.hasData
                              ? CoolDownWidget(
                                  remaining: snapshot.data.percent,
                                  text:
                                      snapshot.data.remainingSeconds.toString(),
                                )
                              : Container();
                        }),
                  )
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bloc.errorStream.listen((e) {
      if (e != null) {
        _scaffoldKey.currentState.hideCurrentSnackBar();
        _scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Padding(
            child: Text(e.message),
            padding: EdgeInsets.only(top: 24, bottom: 24),
          ),
          duration: Duration(seconds: e.canRetry ? 150 : 3),
          action: e.canRetry
              ? SnackBarAction(
                  label: "RETRY",
                  onPressed: () => _bloc.showBy(TransporterBlocFilter.ALL))
              : null,
        ));
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _bloc.dispose();
  }
}

class _TransporterWidget extends StatelessWidget {
  final Transporter transporter;

  final Function(Transporter) onSelect;
  final Function(Transporter) onFavorite;

  _TransporterWidget(
      {Key key,
      @required this.transporter,
      @required this.onSelect,
      @required this.onFavorite})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      width: 80,
      child: Stack(
        children: [
          InkWell(
            onTap: () {
              onSelect(transporter);
            },
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: Container(
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12),
                    borderRadius: BorderRadius.all(Radius.circular(5))),
                child: Center(
                  child: Text(
                    transporter.name,
                    style: TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 28,
                        color: Colors.black87),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: Container(
              width: 30,
              height: 30,
              child: IconButton(
                padding: EdgeInsets.all(2),
                icon: Icon(
                    transporter.isFavorite ? Icons.star : Icons.star_border,
                    color: Theme.of(context).accentColor),
                onPressed: () {
                  onFavorite(transporter.toggleFavorite());
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}
