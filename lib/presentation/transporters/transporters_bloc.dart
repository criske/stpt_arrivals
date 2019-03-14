import 'package:rxdart/rxdart.dart';
import 'package:stpt_arrivals/data/transporter_repository.dart';
import 'package:stpt_arrivals/models/transporter.dart';
import 'package:stpt_arrivals/presentation/disposable_bloc.dart';

abstract class TransportersBloc implements DisposableBloc {
  final Stream<List<Transporter>> transportersStream = Stream.empty();

  final Stream<PrettyTransporterBlocFilter> selectedFilterStream = Stream.empty();

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

class PrettyTransporterBlocFilter{

  final TransporterBlocFilter filter;

  PrettyTransporterBlocFilter([this.filter = TransporterBlocFilter.ALL]);

  @override
  String toString() => _prettyTransporterBlocFilter(filter);

  @override
  bool operator ==(other)  =>  other is PrettyTransporterBlocFilter && filter == other.filter;

  @override
  int get hashCode => filter.hashCode;


}

Iterable<PrettyTransporterBlocFilter> prettyTransporterBlocFilterValues()=> TransporterBlocFilter
    .values.map((f) => PrettyTransporterBlocFilter(f));

_prettyTransporterBlocFilter(TransporterBlocFilter filter){
  final val = filter.toString().split("TransporterBlocFilter.")[1];
  return val[0] + val.substring(1).toLowerCase();
}

class TransportersBlocImpl implements TransportersBloc {
  BehaviorSubject<_Action> _actionsSubject = BehaviorSubject()
    ..add(_ActionAll());

  BehaviorSubject<PrettyTransporterBlocFilter> _selectedFilterSubject = BehaviorSubject()
    ..add(PrettyTransporterBlocFilter(TransporterBlocFilter.ALL));

  TransporterRepository _repository;

  TransportersBlocImpl(this._repository);

  @override
  Stream<List<Transporter>> get transportersStream =>
      _actionsSubject.switchMap((action) {
        if (action is _ActionUpdate) {
          return Observable.fromFuture(_repository.update(action.transporter))
              .concatMap((_) => _findTransportersByAction(action.lastAction));
        } else {
          return _findTransportersByAction(action);
        }
      });

  Observable<List<Transporter>> _findTransportersByAction(_Action action) {
    if (action is _ActionAll) {
      return Observable.fromFuture(_repository.findAll());
    } else if (action is _ActionType) {
      return Observable.fromFuture(_repository.findAllByType(action.type));
    } else if (action is _ActionFavorites) {
      return Observable.fromFuture(_repository.findAllByFavorites());
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
  Stream<PrettyTransporterBlocFilter> get selectedFilterStream => _selectedFilterSubject.stream;
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
