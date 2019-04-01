import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:stpt_arrivals/models/transporter.dart';
import 'package:stpt_arrivals/presentation/transporters/transporters_bloc.dart';
import 'package:stpt_arrivals/ui/application_state_widget.dart';
import 'package:stpt_arrivals/ui/wait_widget.dart';

class TransportersScreen extends StatefulWidget {
  @override
  _TransportersScreenState createState() => _TransportersScreenState();
}

class _TransportersScreenState extends State<TransportersScreen> {
  TransportersBloc _bloc;

  static final int _pageFilter = 0;
  static final int _pageSearch = 1;

  var _selectedDropFilter = PrettyTransporterBlocFilter();

  final topPageController = PageController();

  final _searchTextFocusNode = FocusNode();
  final _searchTextFocusNodeReleased = FocusNode();

  @override
  void initState() {
    super.initState();
    _bloc = TransportersBlocImpl(
      ApplicationStateWidget.of(context).bloc.transportersRepository,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ApplicationStateWidget.of(context).bloc.switchLastCoolDown();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Material(
          elevation: 2,
          child: Container(
            height: 56,
            margin: EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: PageView(
                  onPageChanged: ((p) {
                    if (p == _pageSearch) {
                      _selectedDropFilter = PrettyTransporterBlocFilter(
                          TransporterBlocFilter.SEARCH);
                      FocusScope.of(context).requestFocus(_searchTextFocusNode);
                    } else {
                      FocusScope.of(context)
                          .requestFocus(_searchTextFocusNodeReleased);
                    }
                  }),
                  controller: topPageController,
                  children: [_filterWidget(), _searchTransporterWidget()]),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 16, right: 8, left: 8),
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
                                      Navigator.pushNamed(context, "/arrivals",
                                          arguments: t);
                                    },
                                    onFavorite: (t) {
                                      _bloc.update(t);
                                    },
                                  ))
                              .toList(),
                        ),
                      );
                    } else {
                      return Center(child: WaitWidget());
                    }
                  }),
              Center(
                child: StreamBuilder<bool>(
                  stream: _bloc.loadingStream,
                  builder: (_, snapshot) {
                    return Opacity(
                      opacity: snapshot.hasData ? snapshot.data ? 1 : 0 : 1,
                      child: WaitWidget(),
                    );
                  },
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Row _filterWidget() {
    return Row(
      children: <Widget>[
        Padding(
            padding: EdgeInsets.all(4),
            child: IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                _jumpToTopPage(_pageSearch);
              },
            )),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: StreamBuilder<bool>(
                stream: _bloc.loadingStream,
                builder: (context, snapshot) {
                  final enabled = snapshot.hasData ? !snapshot.data : false;
                  return DropdownButton<PrettyTransporterBlocFilter>(
                      isExpanded: true,
                      onChanged: enabled
                          ? (PrettyTransporterBlocFilter value) {
                              setState(() {
                                _selectedDropFilter = value;
                              });
                              if (value.filter ==
                                  TransporterBlocFilter.SEARCH) {
                                _jumpToTopPage(_pageSearch);
                              } else {
                                _bloc.showBy(value.filter);
                              }
                            }
                          : null,
                      //todo need to use a stream here but is bugged?
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
        IconButton(
          onPressed: ()=> _bloc.refresh(),
          icon: Icon(Icons.cloud_download),
        ),
        Container(
          child: StreamBuilder<List<Transporter>>(
              //Note: if not broadcast I'm getting error :"Bad state: Stream has already been listened to."
              stream: _bloc.historyStream.asBroadcastStream(),
              builder: (_, snapshot) {
                if (!snapshot.hasData || snapshot.data.isEmpty) {
                  return Container();
                } else {
                  return PopupMenuButton(
                      icon: Icon(Icons.history),
                      onSelected: (t) => Navigator.pushNamed(
                          context, "/arrivals",
                          arguments: t),
                      itemBuilder: (_) => snapshot.data
                          .map((t) => PopupMenuItem(
                              value: t,
                              child: Text(
                                t.name,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 18),
                              )))
                          .toList());
                }
              }),
        )
      ],
    );
  }

  void _jumpToTopPage(int page) {
    topPageController.animateToPage(page,
        duration: Duration(milliseconds: 300), curve: Curves.linear);
  }

  Row _searchTransporterWidget() {
    return Row(
      children: <Widget>[
        IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            FocusScope.of(context).requestFocus(_searchTextFocusNodeReleased);
            _jumpToTopPage(_pageFilter);
          },
        ),
        SizedBox(
          width: 32,
        ),
        Expanded(
          child: TextField(
            focusNode: _searchTextFocusNode,
            decoration:
                InputDecoration(border: InputBorder.none, hintText: 'Cauta...'),
            onChanged: (text) {
              _bloc.showBy(TransporterBlocFilter.SEARCH, text);
            },
          ),
        )
      ],
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bloc.errorStream.listen((e) {
      if (e != null) {
        Scaffold.of(context).hideCurrentSnackBar();
        Scaffold.of(context).showSnackBar(SnackBar(
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
    _searchTextFocusNode.dispose();
    _searchTextFocusNodeReleased.dispose();
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
                        fontSize: 22,
                        color: Colors.black54),
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
                    color: transporter.isFavorite ? Theme.of(context).accentColor : Colors.grey[300]),
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
