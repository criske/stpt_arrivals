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

  void showBy(TransporterBlocFilter type);

  void update(Transporter transporter);
}

enum TransporterBlocFilter {
  ALL,
  BUS,
  BOAT,
  TRAM,
  TROLLEY,
  FAVORITE,
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

_prettyTransporterBlocFilter(TransporterBlocFilter filter) {
  final val = filter.toString().split("TransporterBlocFilter.")[1];
  return val[0] + val.substring(1).toLowerCase();
}

class TransportersBlocImpl implements TransportersBloc {
  final BehaviorSubject<_Action> _actionsSubject = BehaviorSubject()
    ..add(_ActionAll());

  final BehaviorSubject<PrettyTransporterBlocFilter> _selectedFilterSubject =
      BehaviorSubject()
        ..add(PrettyTransporterBlocFilter(TransporterBlocFilter.ALL));

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
                        .onErrorReturnWith((e)=>_ResultError(e)));
          } else {
            return _findTransportersByAction(action)
                .startWith(_ResultLoading.inst)
                .onErrorReturnWith((e)=>_ResultError(e));
          }
        })
        .scan(_stateReducer, _State.init)
        .share();
  }

  _State _stateReducer(_State acc, _Result curr, _) {
    if (curr is _ResultError) {
      return acc.nextError(_errMapper(curr.err));
    } else if (curr is _ResultSuccess) {
      return _State(curr.transporters, false, null);
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
      _stateObservable.map((s) => s.loading).distinct();

  Observable<_Result> _findTransportersByAction(_Action action) {
    if (action is _ActionAll) {
      return Observable.fromFuture(_repository.findAll())
          .map((l) => _ResultSuccess(l));
    } else if (action is _ActionType) {
      return Observable.fromFuture(_repository.findAllByType(action.type))
          .map((l) => _ResultSuccess(l));
    } else if (action is _ActionFavorites) {
      return Observable.fromFuture(_repository.findAllByFavorites())
          .map((l) => _ResultSuccess(l));
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
    _selectedFilterSubject.close();
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
  void showBy(TransporterBlocFilter type) {
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
    }
    _selectedFilterSubject.add(PrettyTransporterBlocFilter(type));
  }

  @override
  Stream<PrettyTransporterBlocFilter> get selectedFilterStream =>
      _selectedFilterSubject.stream;

  @override
  Stream<ErrorUI> get errorStream => _stateObservable.map((s) => s.error);
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

class _State {
  static final _State init = _State([], false, null);

  final List<Transporter> transporters;
  final bool loading;
  final ErrorUI error;

  _State(this.transporters, this.loading, this.error);

  _State nextLoading(bool loading) => _State(transporters, loading, null);

  _State nextError(ErrorUI error) => _State(transporters, false, error);
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

  _ResultSuccess(this.transporters);
}
