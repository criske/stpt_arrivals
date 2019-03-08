import 'dart:async';

import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';
import 'package:stpt_arrivals/models/arrival.dart';
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
  void cancel() {}

  @override
  void load(int transporterId) {
    actionLoadSubject
        .add(_Action.load(_timeProvider.timeMillis(), transporterId));
  }

  @override
  void toggleWay() {
    actionToggleSubject.add(_Action.toggleWay(_timeProvider.timeMillis()));
  }

  @override
  void dispose() {
    actionLoadSubject.sink.close();
  }

  @override
  Stream<Result> get streamResult {
    final loadStream = actionLoadSubject.stream.scan(coolDownScanner, _Action.idle);
    final toggleStream = actionToggleSubject.stream;

    return Observable.merge([loadStream, toggleStream]).flatMap((action) {
      if (action is _ActionIdle) {
        return Observable.just(_State.idle());
      } else if (action is _ActionLoad) {
        return Observable
            .fromFuture(_arrivalFetcher.getRouteArrivals(action.transporterId))
            .map((route) => _State.withRoute(route))
            .startWith(_State.loading());
      } else if (action is _ActionCoolDown) {
        return Observable
            .just(_State.withError(CoolDownError(action.remainingSeconds)));
      }
    }).scan((_State acc, _State curr, _) {
      _State state;
      switch (curr.transientState) {
        case TransientState.FINISHED:
        case TransientState.IDLE:
          state = curr;
          break;
        case TransientState.LOADING:
          state = _State(acc.toggleableRoute, curr.transientState, null);
          break;
        case TransientState.TOGGLE:
          state = _State(
              acc.toggleableRoute.toggle(), TransientState.FINISHED, null);
          break;
        case TransientState.ERROR:
          state = _State(acc.toggleableRoute, curr.transientState, curr.error);
          break;
      }
      return state;
    }, _State.idle()).map((state) {
      Result result;
      switch (state.transientState) {
        case TransientState.IDLE:
          result = Result.idle;
          break;
        case TransientState.LOADING:
          result = Result.loading;
          break;
        case TransientState.ERROR:
          result = ResultError(state.error);
          break;
        case TransientState.FINISHED:
        case TransientState.TOGGLE:
          result = Result.display(state.toggleableRoute.getWay());
          break;
      }
      return result;
    });
  }

  _Action coolDownScanner(acc, curr, _) {
    if (acc == null || acc == _Action.idle) {
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
      _State(ToggleableRoute(route), TransientState.FINISHED, null);

  factory _State.loading() => _State(null, TransientState.LOADING, null);

  factory _State.idle() => _State(null, TransientState.IDLE, null);

  factory _State.toggle() => _State(null, TransientState.TOGGLE, null);

  factory _State.withError(Error error) =>
      _State(null, TransientState.ERROR, error);

  final ToggleableRoute toggleableRoute;

  final TransientState transientState;

  final Error error;

  const _State([this.toggleableRoute, this.transientState, this.error]);
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

enum TransientState { IDLE, LOADING, FINISHED, TOGGLE, ERROR }

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
