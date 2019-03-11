import 'dart:async';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';
import 'package:stpt_arrivals/models/arrival.dart';
import 'package:stpt_arrivals/models/error.dart';
import 'package:stpt_arrivals/presentation/arrival_ui.dart';
import 'package:stpt_arrivals/services/parser/time_converter.dart';
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

  ArrivalTimeConverter _arrivalTimeConverter;

  RouteArrivalFetcher _arrivalFetcher;

  ArrivalState _initialState;

  Observable<ArrivalState> _stateObservable;

  ArrivalDisplayBlocImpl(
      this._timeProvider, this._arrivalTimeConverter, this._arrivalFetcher,
      [this._initialState]) {
    var loadStream =
        _actionLoadSubject.stream.scan(_coolDownController, _Action.idle);
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
      .map((s)=> s.toggleableRoute.getWay().arrivals)
      .distinct((prev, next) => ListEquality().equals(prev, next))
      .map((arrivals) => arrivals.map((a) {
    //final now = _timeProvider.timeMillis();
    //          final time1Diff = Duration(milliseconds: a.time.millis) -
//                  Duration(milliseconds: now)
    final time1 = TimeUI(
        _arrivalTimeConverter.toReadableTime(a.time.millis, "HH:mm"));

    final time2 = a.time2 == null ? TimeUI.none : TimeUI(
        _arrivalTimeConverter.toReadableTime(a.time2.millis, "HH:mm"));
        return ArrivalUI(a.station.id, a.station.name, time1, time2);
        }).toList());

  @override
  Stream<ErrorUI> get errorStream => _stateObservable
          .skipWhile((s) {
            return s.flag != StateFlag.ERROR;
          })
          .map((s) => s.error)
          .distinct()
          .map((e) {
        var msg;
        if (e is CoolDownError) {
          msg = "Wait ${e.remainingSeconds} seconds more and then try again";
        } else if (e is ExceptionError) {
          var exStr = e.exception.toString();
          msg = exStr.substring(exStr.indexOf(" "));
        } else if (e is MessageError) {
          msg = e.message;
        } else {
          msg = e.toString();
        }
        return ErrorUI(msg);
      });

  @override
  Stream<bool> get loadingStream =>
      _stateObservable.map((s) => s.flag == StateFlag.LOADING).distinct();

  @override
  Stream<String> get wayNameStream =>
      _stateObservable.map((s) => s.toggleableRoute.getWay().name).distinct();

  _Action _coolDownController(acc, curr, _) {
    if (acc is _ActionIdle || curr is _ActionIdle) {
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
          .doOnError((_, __) {
            _actionLoadSubject.add(_Action.idle);
          })
          .onErrorReturnWith((e) => ArrivalState.partialError(e))
          .startWith(ArrivalState.partialFlag(StateFlag.LOADING))
          .takeUntil(_actionCancelSubject.stream
              .doOnData((_) => _actionLoadSubject.add(_Action.idle)));
    } else if (action is _ActionCoolDown) {
      return Observable.just(
          ArrivalState.partialError(CoolDownError(action.remainingSeconds)));
    } else if (action is _ActionToggle) {
      return Observable.just(ArrivalState.partialFlag(StateFlag.TOGGLE));
    } else {
      return Observable.just(ArrivalState.partialError(
          MessageError("Unprocessed action $action")));
    }
  }

  ArrivalState _stateReducer(ArrivalState acc, ArrivalState curr, _) {
    ArrivalState state;
    switch (curr.flag) {
      case StateFlag.FINISHED:
        state = ArrivalState(curr.toggleableRoute, curr.flag, null);
        break;
      case StateFlag.IDLE:
      case StateFlag.LOADING:
        state = ArrivalState(acc.toggleableRoute, curr.flag, null);
        break;
      case StateFlag.TOGGLE:
        state = ArrivalState(
            acc.toggleableRoute.toggle(), StateFlag.FINISHED, null);
        break;
      case StateFlag.ERROR:
        state = ArrivalState(acc.toggleableRoute, curr.flag, curr.error);
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
      ArrivalState(ToggleableRoute(route), StateFlag.FINISHED, null);

  factory ArrivalState.partialFlag(StateFlag flag) =>
      ArrivalState(_emptyRoute, flag, null);

  factory ArrivalState.partialError(dynamic error) {
    Error err;
    if (error is Error) {
      err = error;
    } else if (error is Exception) {
      err = ExceptionError(error);
    } else {
      throw Exception("error must be eather an Error or an Exception");
    }
    return ArrivalState(null, StateFlag.ERROR, err);
  }

  ArrivalState nextRoute(ToggleableRoute route) =>
      ArrivalState(route, this.flag, this.error);

  ArrivalState nextFlag(StateFlag flag) =>
      ArrivalState(this.toggleableRoute, flag, this.error);

  ArrivalState nextError(Error error) =>
      ArrivalState(this.toggleableRoute, this.flag, error);

  final ToggleableRoute toggleableRoute;

  final StateFlag flag;

  final Error error;

  const ArrivalState([this.toggleableRoute, this.flag, this.error]);

  static ArrivalState defaultState =
      ArrivalState(_emptyRoute, StateFlag.IDLE, null);

  @override
  bool operator ==(other) =>
      other is ArrivalState &&
      this.flag == other.flag &&
      this.error == other.error &&
      this.toggleableRoute == other.toggleableRoute;

  @override
  int get hashCode => hashValues(toggleableRoute, flag, error);

  @override
  String toString() =>
      "ArrivalState[route:$toggleableRoute, flat:$flag, error:$error]";
}

enum StateFlag { IDLE, LOADING, FINISHED, TOGGLE, ERROR }

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
