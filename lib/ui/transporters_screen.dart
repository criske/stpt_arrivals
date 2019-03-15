import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:stpt_arrivals/data/favorites_data_source.dart';
import 'package:stpt_arrivals/data/transporters_repository.dart';
import 'package:stpt_arrivals/models/transporter.dart';
import 'package:stpt_arrivals/presentation/transporters/transporters_bloc.dart';
import 'package:stpt_arrivals/ui/arrival_display_screen.dart';

class TransportersScreen extends StatefulWidget {
  @override
  _TransportersScreenState createState() => _TransportersScreenState();
}

class _TransportersScreenState extends State<TransportersScreen> {
  TransportersBloc _bloc;

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  var _selectedDropFilter = PrettyTransporterBlocFilter();

  _TransportersScreenState() {
    _bloc = TransportersBlocImpl(
        TransportersRepositoryImpl.withData(FavoritesDataSourceImpl(), [
      Transporter("886", "40", TransporterType.bus),
      Transporter("1551", "E2", TransporterType.bus),
      Transporter("1550", "E1", TransporterType.bus),
      Transporter("1547", "E8", TransporterType.bus),
      Transporter("1046", "33", TransporterType.bus),
      Transporter("2466", "33b", TransporterType.bus),
      Transporter("1006", "14", TransporterType.trolley),
      Transporter("2766", "M14", TransporterType.trolley),
      Transporter("1106", "1", TransporterType.tram),
      Transporter("1126", "2", TransporterType.tram),
    ]));
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
                          child: DropdownButton<PrettyTransporterBlocFilter>(
                              isExpanded: true,
                              onChanged: (PrettyTransporterBlocFilter value) {
                                setState(() {
                                  _selectedDropFilter = value;
                                });
                                _bloc.showBy(value.filter);
                              },
                              items: prettyTransporterBlocFilterValues()
                                  .map((f) => DropdownMenuItem(
                                        value: f,
                                        child: Text(f.toString()),
                                      ))
                                  .toList(),
                              value: _selectedDropFilter),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: StreamBuilder<List<Transporter>>(
                  stream: _bloc.transportersStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Wrap(
                        runSpacing: 4,
                        spacing: 4,
                        children: snapshot.data
                            .map((t) => _TransporterWidget(
                                  transporter: t,
                                  onSelect: (t) {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                ArrivalDisplayScreen(t)));
                                  },
                                  onFavorite: (t) {
                                    _bloc.update(t);
                                  },
                                ))
                            .toList(),
                      );
                    } else {
                      return Center(child: CircularProgressIndicator());
                    }
                  }),
            ),
          ],
        ),
      ),
    );
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
