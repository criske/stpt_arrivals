import 'dart:io';

import 'package:async/async.dart';
import 'package:mockito/mockito.dart';
import 'package:stpt_arrivals/models/arrival.dart';
import 'package:stpt_arrivals/presentation/arrival_display_bloc.dart' as blc;
import 'package:stpt_arrivals/presentation/arrival_ui.dart';
import 'package:stpt_arrivals/presentation/time_ui_converter.dart';
import 'package:test_api/test_api.dart';

import 'mocks.dart';

//todo repair tests errQueue hangs?
void main() {
  TimelineTimeProvider timeline;
  MockRouteArrivalFetcher fetcher;
  blc.ArrivalDisplayBloc bloc;
  StreamQueue<blc.ArrivalState> queue;
  StreamQueue<ErrorUI> errQueue;
  blc.ArrivalState state;

  Route route = Route(Way(List(), "Way1"), Way(List(), "Way2"));
  blc.ToggleableRoute toggleableRoute = blc.ToggleableRoute(route);

  Future<String> nextErrMessage() async => (await errQueue.next).message;

  setUp(() {
    timeline = TimelineTimeProvider();
    fetcher = MockRouteArrivalFetcher();
    bloc = blc.ArrivalDisplayBlocImpl(timeline, TimeUIConverterImpl(), fetcher,
        MockRestoringCoolDownManager());
    queue = StreamQueue(bloc.streamState);
    errQueue = StreamQueue(bloc.errorStream);
    state = blc.ArrivalState.defaultState;
  });

  test("should emit [LOADING, DISPLAY]", () async {
    when(fetcher.getRouteArrivals(100)).thenAnswer((_) async {
      return route;
    });
    bloc.load(100);
    state = state.nextFlag(blc.StateFlag.LOADING);
    expect(await queue.next, state);
    state = state.nextRoute(toggleableRoute).nextFlag(blc.StateFlag.FINISHED);
    expect(await queue.next, state);
  });

  test("should emit [DISPLAY, COOLDOWN-ERR, DISPLAY]", () async {
    when(fetcher.getRouteArrivals(100)).thenAnswer((_) async {
      return Route(Way(List(), "Way1"), Way(List(), "Way2"));
    });

    bloc.load(100);
    await queue.next;
    await queue.next;
    timeline.advance(Duration(seconds: 3));
    bloc.load(100);
    state = state.nextRoute(toggleableRoute).nextFlag(blc.StateFlag.IDLE);
    expect(await queue.next, state);
    //expect((await errQueue.next).message, "Wait 27 seconds more and then try again");
    timeline.advance(Duration(seconds: 60));
    bloc.load(100);
    await queue.next;
    state = state.nextError(null).nextFlag(blc.StateFlag.FINISHED);
    expect(await queue.next, state);
  });

  test("should emit [LOADING, DISPLAY, TOGGLE]", () async {
    when(fetcher.getRouteArrivals(100)).thenAnswer((_) async {
      return Route(Way(List(), "Way1"), Way(List(), "Way2"));
    });

    state = state.nextFlag(blc.StateFlag.FINISHED).nextRoute(toggleableRoute);
    bloc = blc.ArrivalDisplayBlocImpl(timeline, TimeUIConverterImpl(), fetcher,
        MockRestoringCoolDownManager(), state);
    queue = StreamQueue(bloc.streamState);
    bloc.toggleWay();
    await queue.next;
    state = state.nextRoute(toggleableRoute.toggle());
    expect(await queue.next, state);
  });

//  test("should emit [LOADING, ERROR]", () async {
//    when(fetcher.getRouteArrivals(100)).thenAnswer((_) async {
//      throw Exception("Boom!");
//    });
//
//    bloc.load(100);
//    await queue.next;
//    final err = (((await queue.next).error) as ExceptionError).exception;
//    expect(err.toString(), "Exception: Boom!");
//  });

  test("should emit [LOADING, IDLE] when cancel", () async {
    when(fetcher.getRouteArrivals(100)).thenAnswer((_) async {
      sleep(Duration(milliseconds: 300));
      return Route(Way(List(), "Way1"), Way(List(), "Way2"));
    });
    bloc.load(100);
    bloc.cancel();
    await queue.next;
    expect(await queue.next, state);
  });
}
