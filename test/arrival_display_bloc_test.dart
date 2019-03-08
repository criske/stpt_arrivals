import 'package:async/async.dart';
import 'package:mockito/mockito.dart';
import 'package:stpt_arrivals/models/arrival.dart';
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
}
