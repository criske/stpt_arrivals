import 'dart:io';

import 'package:async/async.dart';
import 'package:mockito/mockito.dart';
import 'package:stpt_arrivals/models/arrival.dart';
import 'package:stpt_arrivals/models/error.dart';
import 'package:stpt_arrivals/presentation/arrival_display_bloc.dart' as blc;
import 'package:test/test.dart';

import 'mocks.dart';

void main() {
  TimelineTimeProvider timeline;
  MockRouteArrivalFetcher fetcher;
  blc.ArrivalDisplayBloc bloc;

  setUp(() {
    timeline = TimelineTimeProvider();
    fetcher = MockRouteArrivalFetcher();
    bloc = blc.ArrivalDisplayBlocImpl(timeline, fetcher);
  });

  test("should emit [LOADING, DISPLAY]", () async {
    when(fetcher.getRouteArrivals(100)).thenAnswer((_) async {
      return Route(Way(List(), "Way1"), Way(List(), "Way2"));
    });

    final stream = StreamQueue(bloc.streamResult);
    bloc.load(100);
    expect(await stream.next, blc.Result.loading);
    expect(true, (await stream.next) is blc.ResultDisplay);
  });

  test("should emit [LOADING, DISPLAY, COOLDOWN-ERR, DISPLAY]", () async {
    when(fetcher.getRouteArrivals(100)).thenAnswer((_) async {
      return Route(Way(List(), "Way1"), Way(List(), "Way2"));
    });

    final stream = StreamQueue(bloc.streamResult);
    bloc.load(100);
    expect(await stream.next, blc.Result.loading);
    expect(true, (await stream.next) is blc.ResultDisplay);
    bloc.load(100);
    expect(true, (await stream.next) is blc.ResultError);
    timeline.advance(Duration(seconds: 60));
    bloc.load(100);
    expect(await stream.next, blc.Result.loading);
    expect(true, (await stream.next) is blc.ResultDisplay);
  });

  test("should emit [LOADING, DISPLAY, TOGGLE]", () async {
    when(fetcher.getRouteArrivals(100)).thenAnswer((_) async {
      return Route(Way(List(), "Way1"), Way(List(), "Way2"));
    });

    final stream = StreamQueue(bloc.streamResult);
    bloc.load(100);
    expect(await stream.next, blc.Result.loading);
    var rd = (await stream.next) as blc.ResultDisplay;
    expect("Way1", rd.way.name);
    bloc.toggleWay();
    rd = (await stream.next) as blc.ResultDisplay;
    expect("Way2", rd.way.name);
  });

  test("should emit [LOADING, ERROR]", () async {
    when(fetcher.getRouteArrivals(100)).thenAnswer((_) async {
      throw Exception("Boom!");
    });

    final stream = StreamQueue(bloc.streamResult);
    bloc.load(100);
    expect(await stream.next, blc.Result.loading);
    final err = (await stream.next) as blc.ResultError;
    expect(
        "Exception: Boom!", (err.error as ExceptionError).exception.toString());
  });

  test("should emit [LOADING, IDLE] when cancel", () async {
    when(fetcher.getRouteArrivals(100)).thenAnswer((_) async {
      sleep(Duration(milliseconds: 300));
      return Route(Way(List(), "Way1"), Way(List(), "Way2"));
    });

    final stream = StreamQueue(bloc.streamResult);
    bloc.load(100);
    bloc.cancel();
    expect(await stream.next, blc.Result.loading);
    expect(await stream.next, blc.Result.idle);
  });
}
