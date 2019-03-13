import 'dart:async';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';
import 'package:stpt_arrivals/models/arrival.dart';
import 'package:stpt_arrivals/models/error.dart';
import 'package:stpt_arrivals/presentation/arrival_ui.dart';
import 'package:stpt_arrivals/presentation/time_ui_converter.dart';
import 'package:stpt_arrivals/services/parser/time_converter.dart';
import 'package:stpt_arrivals/services/restoring_cooldown_manager.dart';
import 'package:stpt_arrivals/services/route_arrival_fetcher.dart';

abstract class ArrivalDisplayBloc implements DisposableBloc {
  static const Duration coolDownThreshold = const Duration(seconds: 30);

  final Stream<ArrivalState> streamState = Stream.empty();

  final Stream<bool> loadingStream = Stream.empty();

  final Stream<String> wayNameStream = Stream.empty();

  final Stream<ErrorUI> errorStream = Stream.empty();

  final Stream<List<ArrivalUI>> arrivalsStream = Stream.empty();

  void load(int transporterId);

  void cancel();

  void toggleWay();
}

abstract class DisposableBloc {
  void dispose();
}

class ArrivalDisplayBlocImpl implements ArrivalDisplayBloc {
  TimeProvider _timeProvider;

  TimeUIConverter _timeUIConverter;

  RouteArrivalFetcher _arrivalFetcher;

  RestoringCoolDownManager _coolDownManager;

  ArrivalState _initialState;

  Observable<ArrivalState> _stateObservable;

  ArrivalDisplayBlocImpl(this._timeProvider, this._timeUIConverter,
      this._arrivalFetcher, this._coolDownManager,
      [this._initialState]) {
    final loadStream =
        Observable.fromFuture(_coolDownManager.loadLastCoolDown())
            .map((time) {
              final timeDiff = ArrivalDisplayBloc.coolDownThreshold.inSeconds -
                  (Duration(milliseconds: _timeProvider.timeMillis()) -
                          Duration(milliseconds: time))
                      .inSeconds;
              if (timeDiff <= 0) {
                return _Action.idle;
              } else {
                return _ActionCoolDown(time, timeDiff);
              }
            })
            .cast<_Action>()
            .concatWith([_actionLoadSubject.stream])
            .scan(_coolDownController, _Action.idle);
    var toggleStream = _actionToggleSubject.stream;

    _stateObservable = Observable.merge([loadStream, toggleStream])
        .flatMap(_actionController)
        .scan(_stateReducer, _initialState ?? ArrivalState.defaultState)
        .share();
  }

  BehaviorSubject<_Action> _actionLoadSubject = BehaviorSubject<_Action>()
    ..add(_Action.idle);

  BehaviorSubject<_Action> _actionCancelSubject = BehaviorSubject<_Action>();

  BehaviorSubject<_Action> _actionToggleSubject = BehaviorSubject<_Action>();

  PublishSubject<ErrorUI> _errorStream = PublishSubject<ErrorUI>();

  @override
  void cancel() =>
      _actionCancelSubject.add(_Action.cancel(_timeProvider.timeMillis()));

  @override
  void load(int transporterId) => _actionLoadSubject
      .add(_Action.load(_timeProvider.timeMillis(), transporterId));

  @override
  void toggleWay() =>
      _actionToggleSubject.add(_Action.toggleWay(_timeProvider.timeMillis()));

  @override
  void dispose() {
    _actionLoadSubject.sink.close();
    _actionToggleSubject.sink.close();
    _actionCancelSubject.sink.close();
  }

  @override
  Stream<ArrivalState> get streamState => _stateObservable;

  @override
  Stream<List<ArrivalUI>> get arrivalsStream => _stateObservable
      .map((s) => s.toggleableRoute.getWay().arrivals)
      .distinct((prev, next) => ListEquality().equals(prev, next))
      .map((arrivals) => arrivals.map((a) {
            final timeUI1 = _timeUIConverter.toUI(a.time);
            final timeUI2 = _timeUIConverter.toUI(a.time2);
            return ArrivalUI(a.station.id, a.station.name, timeUI1, timeUI2);
          }).toList());

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
      retry = true;
    } else if (e is MessageError) {
      msg = e.message;
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
      _stateObservable.map((s) => s.toggleableRoute.getWay().name).distinct();

  _Action _coolDownController(acc, curr, _) {
    if (acc is _ActionIdle || curr is _ActionIdle || curr is _ActionCoolDown) {
      return curr;
    } else {
      final timeDiff =
          Duration(milliseconds: curr.time) - Duration(milliseconds: acc.time);
      if (timeDiff < ArrivalDisplayBloc.coolDownThreshold) {
        return _ActionCoolDown(
            acc.time,
            ArrivalDisplayBloc.coolDownThreshold.inSeconds -
                timeDiff.inSeconds);
      } else {
        return curr;
      }
    }
  }

  Stream<ArrivalState> _actionController(action) {
    if (action is _ActionIdle) {
      return Observable.just(ArrivalState.partialFlag(StateFlag.IDLE));
    } else if (action is _ActionLoad) {
      return Observable.fromFuture(
              _arrivalFetcher.getRouteArrivals(action.transporterId))
          .map((route) => ArrivalState.partialRoute(route))
          .flatMap((state) => Observable.fromFuture(
                  _coolDownManager.retainLastCoolDown(action.time))
              .map((_) => state))
          .doOnError((e, __) {
            _errorStream.add(_errorMapper(e));
            _actionLoadSubject.add(_Action.idle);
          })
          .onErrorReturnWith((e) => ArrivalState.partialFlag(StateFlag.IDLE))
          .startWith(ArrivalState.partialFlag(StateFlag.LOADING))
          .takeUntil(_actionCancelSubject.stream
              .doOnData((_) => _actionLoadSubject.add(_Action.idle)));
    } else if (action is _ActionCoolDown) {
      return Observable.just(ArrivalState.partialFlag(StateFlag.IDLE)).doOnData(
          (_) => _errorStream.add(ErrorUI(
              "Wait ${action.remainingSeconds} more seconds and then try again")));
    } else if (action is _ActionToggle) {
      return Observable.just(ArrivalState.partialFlag(StateFlag.TOGGLE));
    } else {
      return Observable.just(ArrivalState.partialFlag(StateFlag.IDLE)).doOnData(
          (_) => _errorStream.add(ErrorUI("Unprocessed action $action")));
    }
  }

  ArrivalState _stateReducer(ArrivalState acc, ArrivalState curr, _) {
    ArrivalState state;
    switch (curr.flag) {
      case StateFlag.FINISHED:
        state = ArrivalState(curr.toggleableRoute, curr.flag);
        break;
      case StateFlag.IDLE:
      case StateFlag.LOADING:
        state = ArrivalState(acc.toggleableRoute, curr.flag);
        break;
      case StateFlag.TOGGLE:
        state = ArrivalState(acc.toggleableRoute.toggle(), StateFlag.FINISHED);
        break;
    }
    return state;
  }
}

@immutable
abstract class _Action {
  final int time;

  const _Action(this.time);

  factory _Action.load(transporterId, time) => _ActionLoad(transporterId, time);

  factory _Action.cancel(time) => _ActionCancel(time);

  factory _Action.toggleWay(time) => _ActionToggle(time);

  static const idle = _ActionIdle(0);
}

@immutable
class _ActionLoad extends _Action {
  final int transporterId;

  const _ActionLoad(time, this.transporterId) : super(time);
}

@immutable
class _ActionCancel extends _Action {
  const _ActionCancel(time) : super(time);
}

@immutable
class _ActionCoolDown extends _Action {
  final int remainingSeconds;

  const _ActionCoolDown(time, this.remainingSeconds) : super(time);
}

@immutable
class _ActionToggle extends _Action {
  const _ActionToggle(time) : super(time);
}

@immutable
class _ActionIdle extends _Action {
  const _ActionIdle(time) : super(time);
}

@immutable
class ArrivalState {
  static final _emptyRoute =
      ToggleableRoute(Route(Way(List(), ""), Way(List(), "")));

  factory ArrivalState.partialRoute(Route route) =>
      ArrivalState(ToggleableRoute(route), StateFlag.FINISHED);

  factory ArrivalState.partialFlag(StateFlag flag) =>
      ArrivalState(_emptyRoute, flag);

  ArrivalState nextRoute(ToggleableRoute route) =>
      ArrivalState(route, this.flag);

  ArrivalState nextFlag(StateFlag flag) =>
      ArrivalState(this.toggleableRoute, flag);

  ArrivalState nextError(Error error) =>
      ArrivalState(this.toggleableRoute, this.flag);

  final ToggleableRoute toggleableRoute;

  final StateFlag flag;

  const ArrivalState([this.toggleableRoute, this.flag]);

  static ArrivalState defaultState = ArrivalState(_emptyRoute, StateFlag.IDLE);

  @override
  bool operator ==(other) =>
      other is ArrivalState &&
      this.flag == other.flag &&
      this.toggleableRoute == other.toggleableRoute;

  @override
  int get hashCode => hashValues(toggleableRoute, flag);

  @override
  String toString() => "ArrivalState[route:$toggleableRoute, flat:$flag]";
}

enum StateFlag { IDLE, LOADING, FINISHED, TOGGLE }

@immutable
class ToggleableRoute {
  final Route _route;

  final bool _isWayTo;

  const ToggleableRoute(this._route, [this._isWayTo = true]);

  Way getWay() => _isWayTo ? _route.way1 : _route.way2;

  ToggleableRoute toggle() => ToggleableRoute(this._route, !this._isWayTo);

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
