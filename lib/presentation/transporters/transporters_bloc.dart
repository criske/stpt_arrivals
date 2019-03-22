import 'package:rxdart/rxdart.dart';
import 'package:stpt_arrivals/data/transporters_repository.dart';
import 'package:stpt_arrivals/models/error.dart';
import 'package:stpt_arrivals/models/transporter.dart';
import 'package:stpt_arrivals/presentation/arrivals/arrival_ui.dart';
import 'package:stpt_arrivals/presentation/disposable_bloc.dart';

abstract class TransportersBloc implements DisposableBloc {
  final Stream<List<Transporter>> transportersStream = Stream.empty();

  final Stream<PrettyTransporterBlocFilter> selectedFilterStream =
      Stream.empty();

  final Stream<bool> loadingStream = Stream.empty();

  final Stream<ErrorUI> errorStream = Stream.empty();

  // ignore: avoid_init_to_null
  void showBy(TransporterBlocFilter type, [dynamic extras = null]);

  void update(Transporter transporter);
}

enum TransporterBlocFilter {
  ALL,
  FAVORITE,
  BUS,
  TRAM,
  TROLLEY,
  BOAT,
  SEARCH,
}

class PrettyTransporterBlocFilter {
  final TransporterBlocFilter filter;

  PrettyTransporterBlocFilter([this.filter = TransporterBlocFilter.ALL]);

  @override
  String toString() => _prettyTransporterBlocFilter(filter);

  @override
  bool operator ==(other) =>
      other is PrettyTransporterBlocFilter && filter == other.filter;

  @override
  int get hashCode => filter.hashCode;
}

Iterable<PrettyTransporterBlocFilter> prettyTransporterBlocFilterValues() =>
    TransporterBlocFilter.values.map((f) => PrettyTransporterBlocFilter(f));

String _prettyTransporterBlocFilter(TransporterBlocFilter filter) {
  var pretty;
  switch (filter) {
    case TransporterBlocFilter.ALL:
      pretty = "Toate";
      break;
    case TransporterBlocFilter.BUS:
      pretty = "Autobuze";
      break;
    case TransporterBlocFilter.TRAM:
      pretty = "Tramvaie";
      break;
    case TransporterBlocFilter.TROLLEY:
      pretty = "Troleibuze";
      break;
    case TransporterBlocFilter.BOAT:
      pretty = "Vaporetto";
      break;
    case TransporterBlocFilter.FAVORITE:
      pretty = "Favorite";
      break;
    case TransporterBlocFilter.SEARCH:
      pretty = "Cauta...";
      break;
  }
  return pretty;
}

class TransportersBlocImpl implements TransportersBloc {
  final BehaviorSubject<_Action> _actionsSubject = BehaviorSubject()
    ..add(_ActionAll());

  TransportersRepository _repository;

  Observable<_State> _stateObservable;

  TransportersBlocImpl(TransportersRepository repository) {
    this._repository = repository;
    _stateObservable = _actionsSubject
        .switchMap((action) {
          if (action is _ActionUpdate) {
            return Observable.fromFuture(_repository.update(action.transporter))
                .concatMap((_) => _findTransportersByAction(action.lastAction)
                    .startWith(_ResultLoading.inst)
                    .onErrorReturnWith((e) => _ResultError(e)));
          } else {
            return _findTransportersByAction(action)
                .startWith(_ResultLoading.inst)
                .onErrorReturnWith((e) => _ResultError(e));
          }
        })
        .scan(_stateReducer, _State.init)
        .share();
  }

  _State _stateReducer(_State acc, _Result curr, _) {
    if (curr is _ResultError) {
      return acc.nextError(_errMapper(curr.err));
    } else if (curr is _ResultSuccess) {
      return _State(curr.transporters, curr.filter, false, null);
    } else if (curr is _ResultLoading) {
      return acc.nextLoading(true);
    }
    return acc;
  }

  ErrorUI _errMapper(dynamic e) {
    if (e is Exception) {
      return ErrorUI(e.toString(), true);
    } else if (e is RetryableError) {
      if (e is MessageError) {
        return ErrorUI(e.message, e.canRetry);
      } else {
        return ErrorUI(e.toString(), e.canRetry);
      }
    }
    return ErrorUI("Unkwnown error", false);
  }

  @override
  Stream<List<Transporter>> get transportersStream =>
      _stateObservable.map((s) => s.transporters).distinct();

  @override
  Stream<bool> get loadingStream =>
      _stateObservable.map((s) => s.loading).distinct().startWith(false);

  Observable<_Result> _findTransportersByAction(_Action action) {
    if (action is _ActionAll) {
      return Observable(_repository.streamAll())
          .map((l) => _ResultSuccess(l, TransporterBlocFilter.ALL));
    } else if (action is _ActionType) {
      return Observable(_repository.streamAllByType(action.type))
          .map((l) => _ResultSuccess(l, _typeToFilter(action.type)));
    } else if (action is _ActionFavorites) {
      return Observable(_repository.streamAllByFavorites())
          .map((l) => _ResultSuccess(l, TransporterBlocFilter.FAVORITE));
    } else if (action is _ActionSearch) {
      return Observable(_repository.streamAllContaining(action.input))
          .map((l) => _ResultSuccess(l, TransporterBlocFilter.SEARCH));
    }
    if (action is _ActionUpdate) {
      return Observable.error(Exception("Update Action not allowed here"));
    } else {
      return Observable.error(Exception("Unknown action"));
    }
  }

  @override
  void dispose() {
    _actionsSubject.close();
  }

  @override
  void update(Transporter transporter) {
    var lastAction = _actionsSubject.value;
    if (lastAction is _ActionUpdate) {
      lastAction = (lastAction as _ActionUpdate).lastAction;
    }
    _actionsSubject.add(_ActionUpdate(transporter, lastAction));
  }

  @override
  // ignore: avoid_init_to_null
  void showBy(TransporterBlocFilter type, [dynamic extras = null]) {
    switch (type) {
      case TransporterBlocFilter.ALL:
        _actionsSubject.add(_ActionAll());
        break;
      case TransporterBlocFilter.BUS:
        _actionsSubject.add(_ActionType(TransporterType.bus));
        break;
      case TransporterBlocFilter.BOAT:
        _actionsSubject.add(_ActionType(TransporterType.boat));
        break;
      case TransporterBlocFilter.TRAM:
        _actionsSubject.add(_ActionType(TransporterType.tram));
        break;
      case TransporterBlocFilter.TROLLEY:
        _actionsSubject.add(_ActionType(TransporterType.trolley));
        break;
      case TransporterBlocFilter.FAVORITE:
        _actionsSubject.add(_ActionFavorites());
        break;
      case TransporterBlocFilter.SEARCH:
        _actionsSubject.add(_ActionSearch((extras as String).trim() ?? ""));
        break;
    }
  }

  @override
  Stream<PrettyTransporterBlocFilter> get selectedFilterStream =>
      _stateObservable
          .map((s) => s.filter)
          //.distinct()
          .map((f) => PrettyTransporterBlocFilter(f));

  //.startWith(PrettyTransporterBlocFilter(TransporterBlocFilter.ALL));

  @override
  Stream<ErrorUI> get errorStream => _stateObservable.map((s) => s.error);
}

TransporterBlocFilter _typeToFilter(TransporterType type) {
  var filter;
  switch (type) {
    case TransporterType.bus:
      filter = TransporterBlocFilter.BUS;
      break;
    case TransporterType.tram:
      filter = TransporterBlocFilter.TRAM;
      break;
    case TransporterType.trolley:
      filter = TransporterBlocFilter.TROLLEY;
      break;
    case TransporterType.boat:
      filter = TransporterBlocFilter.BOAT;
      break;
  }
  return filter;
}

abstract class _Action {}

class _ActionType implements _Action {
  final TransporterType type;

  _ActionType(this.type);
}

class _ActionFavorites implements _Action {}

class _ActionAll implements _Action {}

class _ActionUpdate implements _Action {
  final Transporter transporter;
  final _Action lastAction;

  _ActionUpdate(this.transporter, this.lastAction);
}

class _ActionSearch implements _Action {
  final String input;

  _ActionSearch(this.input);
}

class _State {
  static final _State init = _State([], TransporterBlocFilter.ALL, false, null);

  final List<Transporter> transporters;
  final TransporterBlocFilter filter;
  final bool loading;
  final ErrorUI error;

  _State(this.transporters, this.filter, this.loading, this.error);

  _State nextLoading(bool loading) =>
      _State(transporters, filter, loading, null);

  _State nextError(ErrorUI error) => _State(transporters, filter, false, error);
}

abstract class _Result {}

class _ResultLoading implements _Result {
  static final _ResultLoading inst = _ResultLoading();
}

class _ResultError implements _Result {
  final dynamic err;

  _ResultError(this.err);
}

class _ResultSuccess implements _Result {
  final List<Transporter> transporters;
  final TransporterBlocFilter filter;

  _ResultSuccess(this.transporters, this.filter);
}
