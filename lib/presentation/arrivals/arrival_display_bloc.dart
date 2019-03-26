import 'dart:async';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';
import 'package:stpt_arrivals/data/pinned_stations_data_source.dart';
import 'package:stpt_arrivals/models/arrival.dart';
import 'package:stpt_arrivals/models/error.dart';
import 'package:stpt_arrivals/presentation/arrivals/arrival_ui.dart';
import 'package:stpt_arrivals/presentation/arrivals/time_ui_converter.dart';
import 'package:stpt_arrivals/presentation/disposable_bloc.dart';
import 'package:stpt_arrivals/services/route_arrival_fetcher.dart';

abstract class ArrivalDisplayBloc implements DisposableBloc {
  final Stream<ArrivalState> streamState = Stream.empty();

  final Stream<bool> loadingStream = Stream.empty();

  final Stream<String> wayNameStream = Stream.empty();

  final Stream<ErrorUI> errorStream = Stream.empty();

  final Stream<List<ArrivalUI>> arrivalsStream = Stream.empty();

  final Stream<ArrivalUI> pinnedStream = Stream.empty();

  void load(String transporterId);

  void cancel();

  void toggleWay();

  void pin(String stationId, [bool add = true]);
}

class ArrivalDisplayBlocImpl implements ArrivalDisplayBloc {
  TimeUIConverter _timeUIConverter;

  IRouteArrivalFetcher _arrivalFetcher;

  ArrivalState _initialState;

  PinnedStationsDataSource _pinnedStationsDataSource;

  Observable<ArrivalState> _stateObservable;

  ArrivalDisplayBlocImpl(this._timeUIConverter, this._arrivalFetcher,
      this._pinnedStationsDataSource,
      [this._initialState]) {
    _stateObservable = _actionSubject
        .flatMap(_actionController)
        .scan(_stateReducer, _initialState ?? ArrivalState.defaultState)
        .share();
  }

  BehaviorSubject<_Action> _actionSubject = BehaviorSubject<_Action>()
    ..add(_Action.idle);

  PublishSubject<ErrorUI> _errorStream = PublishSubject<ErrorUI>();

  PublishSubject<_ActionCancel> _cancelStream = PublishSubject<_ActionCancel>();

  @override
  void cancel() => _actionSubject.add(_Action.cancel());

  @override
  void load(String transporterId) =>
      _actionSubject.add(_Action.load(transporterId));

  @override
  void toggleWay() => _actionSubject.add(_Action.toggleWay());

  @override
  void dispose() {
    _actionSubject.close();
  }

  @override
  Stream<ArrivalState> get streamState => _stateObservable;

  @override
  Stream<List<ArrivalUI>> get arrivalsStream =>
      _stateObservable
          .map((s) =>
      s.toggleableRoute
          .getWay()
          .arrivals)
          .distinct((prev, next) => ListEquality().equals(prev, next))
          .map((arrivals) => arrivals.map(_mapArrivalToUI).toList());

  ArrivalUI _mapArrivalToUI(Arrival a) {
    final timeUI1 = _timeUIConverter.toUI(a.time);
    final timeUI2 = _timeUIConverter.toUI(a.time2);
    return ArrivalUI(
        a.station.id, a.station.name, timeUI1, timeUI2, a.station.pinned);
  }

  @override
  Stream<ArrivalUI> get pinnedStream =>
      _stateObservable.map((s) {
        final noArrival = Arrival(null, null, null);
        final pinnedArrival = s.toggleableRoute
            .getWay()
            .arrivals
            .firstWhere((a) => a.station.pinned, orElse: () => noArrival);
        return pinnedArrival == noArrival
            ? ArrivalUI.noArrival
            : _mapArrivalToUI(pinnedArrival);
      });

  @override
  Stream<ErrorUI> get errorStream => _errorStream.stream;

  ErrorUI _errorMapper(dynamic e) {
    var msg;
    var retry = false;
    if (e is CoolDownError) {
      msg = "Wait ${e.remainingSeconds} more seconds and try again";
    } else if (e is ExceptionError) {
      var exStr = e.exception.toString();
      msg = exStr.substring(exStr.indexOf(":") + 1).trim();
      retry = e.canRetry;
    } else if (e is MessageError) {
      msg = e.message;
      retry = e.canRetry;
    } else if (e is Exception) {
      var exStr = e.toString();
      msg = exStr.substring(exStr.indexOf(":") + 1).trim();
      retry = true;
    } else {
      msg = "Unknown Error : $e";
    }
    return ErrorUI(msg, retry);
  }

  @override
  Stream<bool> get loadingStream =>
      _stateObservable.map((s) => s.flag == StateFlag.LOADING).distinct();

  @override
  Stream<String> get wayNameStream =>
      _stateObservable.map((s) =>
      s.toggleableRoute
          .getWay()
          .name).distinct();

  Stream<ArrivalState> _actionController(action) {
    if (action is _ActionIdle) {
      return Observable.just(ArrivalState.partialFlag(StateFlag.IDLE));
    } else if (action is _ActionLoad) {
      return Observable.fromFuture(
          _arrivalFetcher.getRouteArrivals(action.transporterId))
          .flatMap((route) =>
          Observable.fromFuture(_pinnedStationsDataSource.getAll())
              .map((pinned) =>
              ArrivalState.partialRoute(ToggleableRoute(route).pin(
                  pinned.firstWhere(
                          (stationId) =>
                      action.transporterId ==
                          Station.extractTransporterId(stationId),
                      orElse: () => null)))
          ))
          .doOnError((e, stack) {
        _errorStream.add(_errorMapper(e));
        _actionSubject.add(_Action.idle);
      })
          .onErrorReturnWith((e) => ArrivalState.partialFlag(StateFlag.IDLE))
          .startWith(ArrivalState.partialFlag(StateFlag.LOADING))
          .takeUntil(_cancelStream.stream
          .doOnData((_) => _actionSubject.add(_Action.idle)));
    } else if (action is _ActionToggle) {
      return Observable.just(ArrivalState.partialFlag(StateFlag.TOGGLE));
    } else if (action is _ActionPinned) {
      return Observable.fromFuture(_partialPinnedState(action));
    } else {
      return Observable.just(ArrivalState.partialFlag(StateFlag.IDLE)).doOnData(
              (_) => _errorStream.add(ErrorUI("Unprocessed action $action")));
    }
  }

  Future<ArrivalState> _partialPinnedState(_ActionPinned action) async {
    if (action.isPinned) {
      await _pinnedStationsDataSource.insert(action.stationId);
    } else {
      await _pinnedStationsDataSource.delete(action.stationId);
    }
    return ArrivalState.partialPinned(
        (action.isPinned) ? action.stationId : null);
  }

  ArrivalState _stateReducer(ArrivalState acc, ArrivalState curr, _) {
    ArrivalState state;
    switch (curr.flag) {
      case StateFlag.FINISHED:
        state = ArrivalState(
            curr.toggleableRoute.wayTo(acc.toggleableRoute._isWayTo),
            curr.flag,
            acc.pinnedStationId);
        break;
      case StateFlag.IDLE:
      case StateFlag.LOADING:
        state =
            ArrivalState(acc.toggleableRoute, curr.flag, acc.pinnedStationId);
        break;
      case StateFlag.TOGGLE:
        state = ArrivalState(acc.toggleableRoute.toggle(), StateFlag.FINISHED,
            acc.pinnedStationId);
        break;
      case StateFlag.PIN:
        state = ArrivalState(acc.toggleableRoute.pin(curr.pinnedStationId),
            StateFlag.FINISHED, curr.pinnedStationId);
        break;
    }
    return state;
  }

  @override
  void pin(String stationId, [bool add = true]) async {
    _actionSubject.add(_ActionPinned(stationId, add));
  }
}

@immutable
abstract class _Action {
  const _Action();

  factory _Action.load(transporterId) => _ActionLoad(transporterId);

  factory _Action.cancel() => _ActionCancel();

  factory _Action.toggleWay() => _ActionToggle();

  static const idle = _ActionIdle();
}

@immutable
class _ActionLoad extends _Action {
  final String transporterId;

  const _ActionLoad(this.transporterId) : super();
}

@immutable
class _ActionCancel extends _Action {
  const _ActionCancel() : super();
}

@immutable
class _ActionToggle extends _Action {
  const _ActionToggle() : super();
}

@immutable
class _ActionIdle extends _Action {
  const _ActionIdle() : super();
}

@immutable
class _ActionPinned extends _Action {
  final String stationId;
  final bool isPinned;

  const _ActionPinned(this.stationId, this.isPinned);
}

@immutable
class ArrivalState {
  static final _emptyRoute =
  ToggleableRoute(Route(Way(List(), ""), Way(List(), "")));

  factory ArrivalState.partialRoute(ToggleableRoute route) =>
      ArrivalState(route, StateFlag.FINISHED, null);

  factory ArrivalState.partialFlag(StateFlag flag) =>
      ArrivalState(_emptyRoute, flag, null);

  factory ArrivalState.partialPinned(String stationId) =>
      ArrivalState(_emptyRoute, StateFlag.PIN, stationId);

  ArrivalState nextRoute(ToggleableRoute route) =>
      ArrivalState(route, this.flag);

  ArrivalState nextFlag(StateFlag flag) =>
      ArrivalState(this.toggleableRoute, flag);

  ArrivalState nextError(Error error) =>
      ArrivalState(this.toggleableRoute, this.flag);

  final ToggleableRoute toggleableRoute;

  final StateFlag flag;

  final String pinnedStationId;

  const ArrivalState([this.toggleableRoute, this.flag, this.pinnedStationId]);

  static ArrivalState defaultState = ArrivalState(_emptyRoute, StateFlag.IDLE);

  @override
  bool operator ==(other) =>
      other is ArrivalState &&
          this.flag == other.flag &&
          this.toggleableRoute == other.toggleableRoute &&
          this.pinnedStationId == other.pinnedStationId;

  @override
  int get hashCode => hashValues(toggleableRoute, flag, pinnedStationId);

  @override
  String toString() =>
      "ArrivalState[route:$toggleableRoute, flat:$flag], pinned:$pinnedStationId";
}

enum StateFlag { IDLE, LOADING, FINISHED, TOGGLE, PIN }

@immutable
class ToggleableRoute {
  final Route _route;

  final bool _isWayTo;

  const ToggleableRoute(this._route, [this._isWayTo = true]);

  Way getWay() => _isWayTo ? _route.way1 : _route.way2;

  ToggleableRoute toggle() => ToggleableRoute(this._route, !this._isWayTo);

  ToggleableRoute pin(String stationId) {
    final arrivalsWay1 = List<Arrival>();
    _route.way1.arrivals.forEach((a) {
      final station = Station(a.station.id, a.station.name,
          stationId != null && a.station.id == stationId);
      arrivalsWay1.add(Arrival(station, a.time, a.time2));
    });
    final arrivalsWay2 = List<Arrival>();
    _route.way2.arrivals.forEach((a) {
      final station = Station(a.station.id, a.station.name,
          stationId != null && a.station.id == stationId);
      arrivalsWay2.add(Arrival(station, a.time, a.time2));
    });
    final newRoute = Route(Way(arrivalsWay1, _route.way1.name),
        Way(arrivalsWay2, _route.way2.name));
    return ToggleableRoute(newRoute, _isWayTo);
  }

  ToggleableRoute wayTo(bool isWayTo) => ToggleableRoute(_route, isWayTo);

  @override
  bool operator ==(other) =>
      other is ToggleableRoute &&
          this._isWayTo == other._isWayTo &&
          this._route == other._route;

  @override
  int get hashCode => hashValues(_route, _isWayTo);

  @override
  String toString() => "ToggleableRoute:[route:$_route, isWayTo:$_isWayTo]";
}

@immutable
class CoolDownError extends Error {
  final int remainingSeconds;

  CoolDownError(this.remainingSeconds);

  @override
  int get hashCode => remainingSeconds.hashCode;

  @override
  bool operator ==(other) =>
      other is CoolDownError && remainingSeconds == other.remainingSeconds;

  @override
  String toString() => "CoolDownError[seconds:$remainingSeconds]";
}
