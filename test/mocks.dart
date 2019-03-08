import 'package:http/http.dart';
import 'package:mockito/mockito.dart';
import 'package:stpt_arrivals/services/parser/route_arrival_parser.dart';
import 'package:stpt_arrivals/services/parser/time_converter.dart';
import 'package:stpt_arrivals/services/route_arrival_fetcher.dart';

class MockRouteArrivalFetcher extends Mock implements RouteArrivalFetcher {}

class MockParser extends Mock implements RouteArrivalParser {}

class MockClient extends Mock implements Client {}

class MockTimeProvider extends Mock implements TimeProvider {}

class TimelineTimeProvider implements TimeProvider {
  DateTime _timeline;

  TimelineTimeProvider([int seedMillis = 0]) {
    _timeline = DateTime.fromMillisecondsSinceEpoch(seedMillis);
  }

  @override
  DateTime time() => _timeline;

  @override
  int timeMillis() => _timeline.millisecondsSinceEpoch;

  void advance(Duration duration) {
    _timeline = _timeline.add(duration);
  }
}
