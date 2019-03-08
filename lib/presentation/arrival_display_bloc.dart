import 'dart:async';

import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';
import 'package:stpt_arrivals/models/arrival.dart';
import 'package:stpt_arrivals/models/error.dart';
import 'package:stpt_arrivals/services/parser/time_converter.dart';
import 'package:stpt_arrivals/services/route_arrival_fetcher.dart';

abstract class ArrivalDisplayBloc implements DisposableBloc {

  final Stream<Result> streamResult;

  void load(int transporterId);

  void cancel();

  void toggleWay();
}

abstract class DisposableBloc {
  void dispose();
}

class ArrivalDisplayBlocImpl implements ArrivalDisplayBloc {
  static const Duration coolDownThreshold = const Duration(seconds: 30);

  TimeProvider _timeProvider;

  RouteArrivalFetcher _arrivalFetcher;

  ArrivalDisplayBlocImpl(this._timeProvider, this._arrivalFetcher);

  BehaviorSubject<_Action> actionLoadSubject = BehaviorSubject<_Action>()
    ..add(_Action.idle);

  BehaviorSubject<_Action> actionCancelSubject = BehaviorSubject<_Action>();

  BehaviorSubject<_Action> actionToggleSubject = BehaviorSubject<_Action>();

  @override
  void cancel() =>
      actionCancelSubject.add(_Action.cancel(_timeProvider.timeMillis()));

  @override
  void load(int transporterId) => actionLoadSubject
      .add(_Action.load(_timeProvider.timeMillis(), transporterId));

  @override
  void toggleWay() =>
      actionToggleSubject.add(_Action.toggleWay(_timeProvider.timeMillis()));

  @override
  void dispose() {
    actionLoadSubject.sink.close();
    actionToggleSubject.sink.close();
    actionCancelSubject.sink.close();
  }

  @override
  Stream<Result> get streamResult {
    final loadStream =
        actionLoadSubject.stream.scan(_coolDownController, _Action.idle);
    final toggleStream = actionToggleSubject.stream;

    return Observable
        .merge([loadStream, toggleStream])
        .flatMap(_actionController)
        .scan(_stateReducer, _State.withFlag(StateFlag.IDLE))
        .map(_stateToResultMapper);
  }

  _Action _coolDownController(acc, curr, _) {
    if (acc == null || acc == _Action.idle || curr == _Action.idle) {
      return curr;
    } else {
      final timeDiff = _timeDiff(acc.time, curr.time);
      if (timeDiff < coolDownThreshold) {
        return _ActionCoolDown(curr.time, timeDiff.inSeconds);
      } else {
        return curr;
      }
    }
  }

  Stream<_State> _actionController(action) {
    if (action is _ActionIdle) {
      return Observable.just(_State.withFlag(StateFlag.IDLE));
    } else if (action is _ActionLoad) {
      return Observable
          .fromFuture(_arrivalFetcher.getRouteArrivals(action.transporterId))
          .map((route) => _State.withRoute(route))
          .onErrorReturnWith((e) => _State.withError(e))
          .startWith(_State.withFlag(StateFlag.LOADING))
          .takeUntil(actionCancelSubject.stream)
          .doOnCancel(() => actionLoadSubject.add(_Action.idle));
    } else if (action is _ActionCoolDown) {
      return Observable
          .just(_State.withError(CoolDownError(action.remainingSeconds)));
    } else if (action is _ActionToggle) {
      return Observable.just(_State.withFlag(StateFlag.TOGGLE));
    } else {
      return Observable
          .just(_State.withError(MessageError("Unprocessed action $action")));
    }
  }

  Result _stateToResultMapper(state) {
    Result result;
    switch (state.flag) {
      case StateFlag.IDLE:
        result = Result.idle;
        break;
      case StateFlag.LOADING:
        result = Result.loading;
        break;
      case StateFlag.ERROR:
        result = ResultError(state.error);
        break;
      case StateFlag.FINISHED:
      case StateFlag.TOGGLE:
        result = Result.display(state.toggleableRoute.getWay());
        break;
    }
    return result;
  }

  _State _stateReducer(_State acc, _State curr, _) {
    _State state;
    switch (curr.flag) {
      case StateFlag.FINISHED:
        state = _State(curr.toggleableRoute, curr.flag, null);
        break;
      case StateFlag.IDLE:
      case StateFlag.LOADING:
        state = _State(acc.toggleableRoute, curr.flag, null);
        break;
      case StateFlag.TOGGLE:
        state = _State(acc.toggleableRoute.toggle(), StateFlag.FINISHED, null);
        break;
      case StateFlag.ERROR:
        state = _State(acc.toggleableRoute, curr.flag, curr.error);
        break;
    }
    return state;
  }

  Duration _timeDiff(int timeMillis1, int timeMillis2) {
    return Duration(milliseconds: timeMillis2) -
        Duration(milliseconds: timeMillis1);
  }
}

@immutable
abstract class _Action {
  final int time;

  const _Action(this.time);

  factory _Action.load(transporterId, time) => _ActionLoad(transporterId, time);

  factory _Action.cancel(time) => _ActionCancel(time);

  factory _Action.toggleWay(time) => _ActionToggle(time);

  static const idle = _ActionIdle(-1);
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

class _ActionToggle extends _Action {
  const _ActionToggle(time) : super(time);
}

class _ActionIdle extends _Action {
  const _ActionIdle(time) : super(time);
}

@immutable
class _State {
  factory _State.withRoute(Route route) =>
      _State(ToggleableRoute(route), StateFlag.FINISHED, null);

  factory _State.withFlag(StateFlag flag) => _State(null, flag, null);

  factory _State.withError(dynamic error) {
    Error err;
    if (error is Error) {
      err = error;
    } else if (error is Exception) {
      err = ExceptionError(error);
    } else {
      throw Exception("error must be eather an Error or an Exception");
    }
    return _State(null, StateFlag.ERROR, err);
  }

  final ToggleableRoute toggleableRoute;

  final StateFlag flag;

  final Error error;

  const _State([this.toggleableRoute, this.flag, this.error]);
}

abstract class Result {
  factory Result.display(way) => ResultDisplay(way);
  static const idle = ResultIdle();
  static const loading = ResultLoading();
}

@immutable
class ResultIdle implements Result {
  const ResultIdle();
}

@immutable
class ResultLoading implements Result {
  const ResultLoading();
}

@immutable
class ResultError implements Result {
  final Error error;

  const ResultError(this.error);
}

@immutable
class ResultDisplay implements Result {
  final Way way;

  const ResultDisplay(this.way);
}

enum StateFlag { IDLE, LOADING, FINISHED, TOGGLE, ERROR }

@immutable
class ToggleableRoute {
  final Route _route;

  final bool _isWayTo;

  const ToggleableRoute(this._route, [this._isWayTo = true]);

  Way getWay() => _isWayTo ? _route.way1 : _route.way2;

  ToggleableRoute toggle() => ToggleableRoute(this._route, !this._isWayTo);
}

class CoolDownError extends Error {
  final int remainingSeconds;

  CoolDownError(this.remainingSeconds);
}
